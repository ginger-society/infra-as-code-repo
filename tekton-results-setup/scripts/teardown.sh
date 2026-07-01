#!/usr/bin/env bash
# =============================================================
# teardown.sh — Delete a pipeline run and all its pods/PVCs
#
# Metadata is kept in PostgreSQL and logs in Loki.
# Query them anytime with: scripts/query-run.sh <run-name>
#
# Usage:
#   scripts/teardown.sh <run-name>
#   scripts/teardown.sh <run-name> --yes    # skip confirmation
# =============================================================
set -euo pipefail

RUN="${1:-}"
SKIP_CONFIRM="${2:-}"
NAMESPACE="default"

[[ -n "$RUN" ]] || { echo "Usage: $0 <run-name> [--yes]"; exit 1; }

echo ""
echo "  This will delete from the cluster (not from durable storage):"
echo "    • PipelineRun: ${RUN}"
echo "    • All pods with label tekton.dev/pipelineRun=${RUN}"
echo "    • All PVCs with label tekton.dev/pipelineRun=${RUN}"
echo ""
echo "  Metadata and logs will remain queryable via:"
echo "    scripts/query-run.sh ${RUN}"
echo ""

if [[ "$SKIP_CONFIRM" != "--yes" ]]; then
  read -r -p "  Proceed? [y/N] " confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || { echo "  Cancelled."; exit 0; }
fi

echo ""

# PipelineRun
if kubectl get pipelinerun "$RUN" -n "$NAMESPACE" &>/dev/null; then
  kubectl delete pipelinerun "$RUN" -n "$NAMESPACE"
  echo "  ✓ Deleted PipelineRun/${RUN}"
else
  echo "  — PipelineRun/${RUN} not found (already deleted)"
fi

# Pods
PODS=$(kubectl get pods -n "$NAMESPACE" \
  -l "tekton.dev/pipelineRun=${RUN}" \
  --no-headers -o custom-columns=":metadata.name" 2>/dev/null || true)
if [[ -n "$PODS" ]]; then
  kubectl delete pods -n "$NAMESPACE" \
    -l "tekton.dev/pipelineRun=${RUN}" --ignore-not-found
  echo "  ✓ Deleted pods for ${RUN}"
else
  echo "  — No pods found for ${RUN}"
fi

# PVCs (workspace volumes)
PVCS=$(kubectl get pvc -n "$NAMESPACE" \
  -l "tekton.dev/pipelineRun=${RUN}" \
  --no-headers -o custom-columns=":metadata.name" 2>/dev/null || true)
if [[ -n "$PVCS" ]]; then
  kubectl delete pvc -n "$NAMESPACE" \
    -l "tekton.dev/pipelineRun=${RUN}" --ignore-not-found
  echo "  ✓ Deleted PVCs for ${RUN}"
else
  echo "  — No PVCs found for ${RUN}"
fi

echo ""
echo "  Cluster is clean. Query durable storage anytime:"
echo "    scripts/query-run.sh ${RUN}          # metadata + logs"
echo "    scripts/query-run.sh ${RUN} --meta   # postgres only"
echo "    scripts/query-run.sh ${RUN} --logs   # loki only"
echo ""
