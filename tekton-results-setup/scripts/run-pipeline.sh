#!/usr/bin/env bash
# =============================================================
# run-pipeline.sh — Trigger and watch a pipeline run
#
# Usage:
#   scripts/run-pipeline.sh <run-name> [repo-url] [revision] [app-name]
#
# Examples:
#   scripts/run-pipeline.sh my-run-001
#   scripts/run-pipeline.sh my-run-002 https://github.com/myorg/myapp main myapp
# =============================================================
set -euo pipefail

RUN_NAME="${1:-}"
REPO_URL="${2:-https://github.com/tektoncd/pipeline}"
REVISION="${3:-main}"
APP_NAME="${4:-my-app}"
NAMESPACE="default"

[[ -n "$RUN_NAME" ]] || { echo "Usage: $0 <run-name> [repo-url] [revision] [app-name]"; exit 1; }

# Check if run already exists
if kubectl get pipelinerun "$RUN_NAME" -n "$NAMESPACE" &>/dev/null; then
  echo "PipelineRun '$RUN_NAME' already exists. Use a different name."
  exit 1
fi

echo ""
echo "▶ Starting PipelineRun: ${RUN_NAME}"
echo "  repo:     ${REPO_URL}"
echo "  revision: ${REVISION}"
echo "  app:      ${APP_NAME}"
echo ""

kubectl apply -f - <<EOF
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  name: ${RUN_NAME}
  namespace: ${NAMESPACE}
spec:
  pipelineRef:
    name: sample-ci-pipeline
  params:
    - name: repo-url
      value: "${REPO_URL}"
    - name: revision
      value: "${REVISION}"
    - name: app-name
      value: "${APP_NAME}"
  workspaces:
    - name: shared-source
      volumeClaimTemplate:
        spec:
          accessModes: [ReadWriteOnce]
          resources:
            requests:
              storage: 500Mi
EOF

echo ""
echo "  Watching progress (Ctrl+C to detach — run continues in background)..."
echo ""

# Watch until completion
kubectl get pipelinerun "$RUN_NAME" -n "$NAMESPACE" -w --output-watch-events 2>/dev/null \
  | while read -r event obj; do
      STATUS=$(echo "$obj" | awk '{print $2}')
      REASON=$(echo "$obj" | awk '{print $3}')
      case "$STATUS/$REASON" in
        True/Succeeded)
          echo ""
          echo "  ✓ ${RUN_NAME} Succeeded"
          echo ""
          echo "  Metadata and logs are now in durable storage."
          echo "  You can delete the run and query it anytime:"
          echo ""
          echo "    kubectl delete pipelinerun ${RUN_NAME} -n ${NAMESPACE}"
          echo "    scripts/query-run.sh ${RUN_NAME}"
          echo ""
          pkill -P $$ kubectl 2>/dev/null || true
          exit 0
          ;;
        False/*)
          echo ""
          echo "  ✗ ${RUN_NAME} Failed: $REASON"
          echo "  Check logs: scripts/query-run.sh ${RUN_NAME} --logs"
          pkill -P $$ kubectl 2>/dev/null || true
          exit 1
          ;;
      esac
    done || true
