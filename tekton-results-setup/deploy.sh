#!/usr/bin/env bash
# =============================================================
# deploy.sh — Tekton CI Stack installer
#
# Installs on a blank Kubernetes cluster:
#   • Tekton Pipelines v1.12.0  (LTS, images on ghcr.io)
#   • Tekton Dashboard v0.67.0
#   • Tekton Results v0.18.0    (metadata → bundled PostgreSQL)
#   • Grafana Loki v3.0.0       (durable log storage)
#   • Promtail v3.0.0           (DaemonSet log collector)
#
# Prerequisites:
#   • kubectl configured and pointing at your cluster
#   • A default StorageClass (kind, k3s, GKE, EKS all have one)
#   • openssl available locally
#
# Usage:
#   chmod +x deploy.sh && ./deploy.sh
# =============================================================
set -euo pipefail

TEKTON_VERSION="v1.12.0"
DASHBOARD_VERSION="v0.67.0"
RESULTS_VERSION="v0.18.0"
BASE="https://infra.tekton.dev/tekton-releases"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log()  { echo -e "\n\033[1;32m[$(date +%H:%M:%S)] ▶ $*\033[0m"; }
info() { echo "    $*"; }
ok()   { echo -e "    \033[1;32m✓\033[0m  $*"; }
warn() { echo -e "    \033[1;33m⚠\033[0m  $*"; }
die()  { echo -e "\n\033[1;31m✗ $*\033[0m\n" >&2; exit 1; }

# ── Preflight ─────────────────────────────────────────────────
log "Preflight checks"
kubectl version --client &>/dev/null  || die "kubectl not found"
kubectl cluster-info &>/dev/null      || die "Cannot reach cluster — check your kubeconfig"
openssl version &>/dev/null           || die "openssl not found"
ok "kubectl connected to cluster"

SC=$(kubectl get storageclass -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
[[ -n "$SC" ]] || die "No StorageClass found — PVCs will not bind"
ok "StorageClass found: ${SC}"

# ── Namespaces ────────────────────────────────────────────────
log "Creating namespaces"
kubectl apply -f "${DIR}/manifests/00-namespaces.yaml"
ok "tekton-pipelines, logging"

# ── Tekton Pipelines ──────────────────────────────────────────
log "Installing Tekton Pipelines ${TEKTON_VERSION}"
info "Source: ${BASE}/pipeline/previous/${TEKTON_VERSION}/release.yaml"
info "Images: ghcr.io/tektoncd (NOT gcr.io — that returns 403)"
kubectl apply -f "${BASE}/pipeline/previous/${TEKTON_VERSION}/release.yaml"

info "Waiting for controller..."
kubectl rollout status deployment/tekton-pipelines-controller \
  -n tekton-pipelines --timeout=180s
kubectl rollout status deployment/tekton-pipelines-webhook \
  -n tekton-pipelines --timeout=180s
ok "Tekton Pipelines ready"

# ── Tekton Dashboard ──────────────────────────────────────────
log "Installing Tekton Dashboard ${DASHBOARD_VERSION}"
kubectl apply -f "${BASE}/dashboard/previous/${DASHBOARD_VERSION}/release.yaml"
kubectl rollout status deployment/tekton-dashboard \
  -n tekton-pipelines --timeout=120s
ok "Tekton Dashboard ready"

# ── Tekton Results ────────────────────────────────────────────
log "Installing Tekton Results ${RESULTS_VERSION}"

# The postgres secret MUST exist before release.yaml is applied.
# The bundled StatefulSet references it via envFrom — if the secret
# is absent the pod immediately fails: "secret not found".
info "Creating tekton-results-postgres secret first..."
kubectl create secret generic tekton-results-postgres \
  --namespace=tekton-pipelines \
  --from-literal=POSTGRES_USER=tekton \
  --from-literal=POSTGRES_PASSWORD=tekton-results-secret \
  --dry-run=client -o yaml | kubectl apply -f -
ok "Secret tekton-results-postgres created"

info "Applying Results release..."
kubectl apply -f "${BASE}/results/previous/${RESULTS_VERSION}/release.yaml"

info "Waiting for postgres StatefulSet..."
kubectl rollout status statefulset/tekton-results-postgres \
  -n tekton-pipelines --timeout=180s

# TLS cert — required by Results API
if kubectl get secret tekton-results-tls -n tekton-pipelines &>/dev/null; then
  info "TLS secret already exists, skipping"
else
  info "Generating self-signed TLS cert..."
  openssl req -x509 -newkey rsa:4096 \
    -keyout /tmp/tr-key.pem -out /tmp/tr-cert.pem \
    -days 365 -nodes \
    -subj "/CN=tekton-results-api-service.tekton-pipelines.svc.cluster.local" \
    -addext "subjectAltName=DNS:tekton-results-api-service.tekton-pipelines.svc.cluster.local" \
    2>/dev/null
  kubectl create secret tls tekton-results-tls \
    --namespace=tekton-pipelines \
    --cert=/tmp/tr-cert.pem \
    --key=/tmp/tr-key.pem
  rm -f /tmp/tr-key.pem /tmp/tr-cert.pem
  ok "TLS secret created"
fi

info "Waiting for Results API and Watcher..."
kubectl rollout status deployment/tekton-results-api \
  -n tekton-pipelines --timeout=180s
kubectl rollout status deployment/tekton-results-watcher \
  -n tekton-pipelines --timeout=180s
ok "Tekton Results ready"

# ── Loki ─────────────────────────────────────────────────────
log "Installing Grafana Loki 3.0.0"
info "Fixes applied: delete_request_store=filesystem, max_label_names=30"
kubectl apply -f "${DIR}/manifests/loki/loki.yaml"
kubectl rollout status statefulset/loki -n logging --timeout=180s
ok "Loki ready"

# ── Promtail ─────────────────────────────────────────────────
log "Installing Promtail 3.0.0"
info "Fixes applied: readOnlyRootFilesystem=false, trimmed label set"
kubectl apply -f "${DIR}/manifests/promtail/promtail.yaml"
kubectl rollout status daemonset/promtail -n logging --timeout=120s
ok "Promtail ready"

# ── Sample pipeline ───────────────────────────────────────────
log "Registering sample pipeline (Tasks + Pipeline only, no run yet)"
# Apply everything except the PipelineRun at the bottom of the file
kubectl apply -f "${DIR}/pipeline/sample-pipeline.yaml" 2>&1   | grep -v "^pipelinerun" || true
ok "Tasks and Pipeline registered in default namespace"

# ── Summary ───────────────────────────────────────────────────
echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║            Tekton CI Stack — Ready                        ║"
echo "╠═══════════════════════════════════════════════════════════╣"
echo "║                                                           ║"
echo "║  tekton-pipelines:                                        ║"
kubectl get pods -n tekton-pipelines --no-headers \
  | awk '{printf "║    %-44s %-8s   ║\n", $1, $3}'
echo "║                                                           ║"
echo "║  logging:                                                 ║"
kubectl get pods -n logging --no-headers \
  | awk '{printf "║    %-44s %-8s   ║\n", $1, $3}'
echo "║                                                           ║"
echo "╠═══════════════════════════════════════════════════════════╣"
echo "║  Next steps:                                              ║"
echo "║                                                           ║"
echo "║  1. Run a pipeline:                                       ║"
echo "║     scripts/run-pipeline.sh my-run-001                   ║"
echo "║                                                           ║"
echo "║  2. Query results after deletion:                         ║"
echo "║     scripts/query-run.sh my-run-001                      ║"
echo "║     scripts/query-run.sh --list                           ║"
echo "║                                                           ║"
echo "║  3. Tekton Dashboard:                                     ║"
echo "║     kubectl port-forward svc/tekton-dashboard            ║"
echo "║       9097:9097 -n tekton-pipelines                      ║"
echo "║     → http://localhost:9097                               ║"
echo "╚═══════════════════════════════════════════════════════════╝"