#!/usr/bin/env bash
# =============================================================
# run-pipeline.sh — Trigger a pipeline run and stream logs live
#
# Discovers tasks and steps from the Pipeline definition,
# constructs pod/container names deterministically, and streams
# each step's logs sequentially as they run.
#
# Usage:
#   scripts/run-pipeline.sh <run-name> [repo-url] [revision] [app-name]
#
# Examples:
#   ./scripts/run-pipeline.sh my-run-001
#   ./scripts/run-pipeline.sh my-run-002 https://github.com/myorg/myapp main myapp
# =============================================================

if [ -z "${BASH_VERSION:-}" ]; then exec bash "$0" "$@"; fi
set -euo pipefail

# ── Args ──────────────────────────────────────────────────────
RUN_NAME="${1:-}"
REPO_URL="${2:-https://github.com/tektoncd/pipeline}"
REVISION="${3:-main}"
APP_NAME="${4:-my-app}"
PIPELINE_NAME="sample-ci-pipeline"
NAMESPACE="default"

[[ -n "$RUN_NAME" ]] || {
  echo "Usage: $0 <run-name> [repo-url] [revision] [app-name]"
  exit 1
}

# ── Helpers ───────────────────────────────────────────────────
green()  { printf '\033[1;32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[1;33m%s\033[0m\n' "$*"; }
red()    { printf '\033[1;31m%s\033[0m\n' "$*"; }
dim()    { printf '\033[2m%s\033[0m\n' "$*"; }
bold()   { printf '\033[1m%s\033[0m\n' "$*"; }

sleep_poll() { sleep "${1:-2}"; }

# Wait for a kubectl jsonpath to become non-empty, return the value
wait_for() {
  local resource="$1" jsonpath="$2" timeout="${3:-120}" interval="${4:-2}"
  local elapsed=0
  while true; do
    local val
    val=$(kubectl get "$resource" -n "$NAMESPACE" \
      -o jsonpath="$jsonpath" 2>/dev/null || true)
    [[ -n "$val" ]] && { echo "$val"; return 0; }
    elapsed=$((elapsed + interval))
    [[ $elapsed -ge $timeout ]] && return 1
    sleep "$interval"
  done
}

# Wait until a TaskRun reaches a terminal state (status != Unknown),
# polling its Condition status rather than guessing from container/pod
# state. This is the actual source of truth for whether a task is done.
wait_for_taskrun_terminal() {
  local taskrun_name="$1" timeout="${2:-600}" interval="${3:-2}"
  local elapsed=0
  while true; do
    local status
    status=$(kubectl get taskrun "$taskrun_name" -n "$NAMESPACE" \
      -o jsonpath='{.status.conditions[0].status}' 2>/dev/null || echo "")
    # "True" = succeeded, "False" = failed, "Unknown"/"" = still running
    if [[ "$status" == "True" || "$status" == "False" ]]; then
      echo "$status"
      return 0
    fi
    elapsed=$((elapsed + interval))
    [[ $elapsed -ge $timeout ]] && { echo ""; return 1; }
    sleep "$interval"
  done
}

# Stream one container's logs, retrying until the pod/container exists
# and is actually running or terminated (not just "not waiting" — an
# EMPTY container state means containerStatuses hasn't been populated
# yet, which is NOT the same as ready-to-stream).
stream_container() {
  local pod="$1" container="$2"
  local max_retries=60 attempt=0

  while true; do
    # Check pod exists
    local phase
    phase=$(kubectl get pod "$pod" -n "$NAMESPACE" \
      -o jsonpath='{.status.phase}' 2>/dev/null || echo "")

    if [[ -z "$phase" ]]; then
      attempt=$((attempt + 1))
      [[ $attempt -ge $max_retries ]] && {
        yellow "    [timeout] Pod $pod never appeared"
        return 1
      }
      sleep 2
      continue
    fi

    # Check container state — wait until it's actually running or
    # terminated. An empty state (containerStatuses not populated yet,
    # right after pod creation) must be retried, not treated as ready.
    local container_state
    container_state=$(kubectl get pod "$pod" -n "$NAMESPACE" \
      -o jsonpath="{.status.containerStatuses[?(@.name==\"${container}\")].state}" \
      2>/dev/null || echo "")

    if [[ -z "$container_state" ]] || echo "$container_state" | grep -q '"waiting"'; then
      attempt=$((attempt + 1))
      [[ $attempt -ge $max_retries ]] && {
        yellow "    [timeout] Container $container in pod $pod never started"
        return 1
      }
      sleep 2
      continue
    fi

    # Stream — kubectl logs blocks until container exits
    kubectl logs "$pod" -n "$NAMESPACE" -c "$container" \
      --follow --timestamps 2>/dev/null || true
    return 0
  done
}

# ── Preflight ─────────────────────────────────────────────────
if kubectl get pipelinerun "$RUN_NAME" -n "$NAMESPACE" &>/dev/null; then
  red "PipelineRun '$RUN_NAME' already exists. Use a different name."
  exit 1
fi

# ── Discover pipeline structure ───────────────────────────────
# Query the Pipeline to get ordered task names and their steps
# This avoids hardcoding and works for any pipeline

echo ""
bold "  Inspecting pipeline: ${PIPELINE_NAME}"

# Get tasks in pipeline order
TASK_NAMES=$(kubectl get pipeline "$PIPELINE_NAME" -n "$NAMESPACE" \
  -o jsonpath='{.spec.tasks[*].taskRef.name}' 2>/dev/null || echo "")

if [[ -z "$TASK_NAMES" ]]; then
  red "  Pipeline '$PIPELINE_NAME' not found in namespace '$NAMESPACE'"
  exit 1
fi

# Build ordered list of: task_name → [step names]
declare -a ORDERED_TASKS=()
declare -A TASK_STEPS=()

# Get pipeline task entries in order (name in pipeline = what becomes pod suffix)
PIPELINE_TASK_NAMES=$(kubectl get pipeline "$PIPELINE_NAME" -n "$NAMESPACE" \
  -o jsonpath='{range .spec.tasks[*]}{.name}{"\n"}{end}' 2>/dev/null)

for pipeline_task_name in $PIPELINE_TASK_NAMES; do
  # Get the taskRef name for this pipeline task
  task_ref=$(kubectl get pipeline "$PIPELINE_NAME" -n "$NAMESPACE" \
    -o jsonpath="{.spec.tasks[?(@.name==\"${pipeline_task_name}\")].taskRef.name}" \
    2>/dev/null || echo "$pipeline_task_name")

  # Get steps from the Task definition
  steps=$(kubectl get task "$task_ref" -n "$NAMESPACE" \
    -o jsonpath='{range .spec.steps[*]}{.name}{"\n"}{end}' 2>/dev/null || echo "")

  ORDERED_TASKS+=("$pipeline_task_name")
  TASK_STEPS["$pipeline_task_name"]="$steps"

  echo "    task: ${pipeline_task_name} (→ ${task_ref})"
  for step in $steps; do
    dim "      step: ${step}"
  done
done

# ── Trigger the run ───────────────────────────────────────────
echo ""
bold "  Starting PipelineRun: ${RUN_NAME}"
dim "    repo:     ${REPO_URL}"
dim "    revision: ${REVISION}"
dim "    app:      ${APP_NAME}"
echo ""

kubectl apply -f - <<EOF
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  name: ${RUN_NAME}
  namespace: ${NAMESPACE}
spec:
  pipelineRef:
    name: ${PIPELINE_NAME}
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
dim "  (Ctrl+C to detach — run continues in background)"
echo ""

# ── Stream logs per task → per step ──────────────────────────
# Pod name pattern: <run-name>-<pipeline-task-name>-pod
# Container name:   step-<step-name>

FAILED=0
START_TIME=$(date +%s)

for task_name in "${ORDERED_TASKS[@]}"; do
  pod_name="${RUN_NAME}-${task_name}-pod"
  steps="${TASK_STEPS[$task_name]}"
  taskrun_name="${RUN_NAME}-${task_name}"

  echo "  ┌─────────────────────────────────────────────"
  bold "  │ Task: ${task_name}  (pod: ${pod_name})"
  echo "  │"

  for step_name in $steps; do
    container="step-${step_name}"
    dim "  │ ▶ step: ${step_name}"
    echo "  │"

    # Stream this step — blocks until step container exits
    stream_container "$pod_name" "$container" \
      | while IFS= read -r line; do
          printf '  │   %s\n' "$line"
        done

    echo "  │"
  done

  # The TaskRun's Condition status is the source of truth for whether
  # the task finished. stream_container may return as soon as its
  # current step's container exits, but later steps in the same task
  # could still be starting up — so wait here until the TaskRun itself
  # reaches a terminal state instead of checking status immediately.
  task_status=$(wait_for_taskrun_terminal "$taskrun_name" 600 2)
  task_reason=$(kubectl get taskrun "$taskrun_name" -n "$NAMESPACE" \
    -o jsonpath='{.status.conditions[0].reason}' 2>/dev/null || echo "")

  if [[ "$task_status" == "True" ]]; then
    green "  │ ✓ ${task_name} succeeded"
  else
    red   "  │ ✗ ${task_name} failed: ${task_reason}"
    FAILED=1
  fi
  echo "  └─────────────────────────────────────────────"
  echo ""

  # Stop streaming if a task failed
  [[ $FAILED -eq 1 ]] && break
done

# ── Final status ──────────────────────────────────────────────
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
if [[ $FAILED -eq 0 ]]; then
  # Wait for PipelineRun to be fully marked complete
  wait_for "pipelinerun/${RUN_NAME}" \
    '{.status.conditions[0].status}' 30 2 >/dev/null || true

  green "  ✓ PipelineRun ${RUN_NAME} succeeded  (${DURATION}s)"
  echo ""
  dim   "  Metadata and logs are in durable storage."
  dim   "  Clean up the cluster when ready:"
  echo ""
  dim   "    ./scripts/teardown.sh ${RUN_NAME}"
  dim   "    ./scripts/query-run.sh ${RUN_NAME}"
else
  red   "  ✗ PipelineRun ${RUN_NAME} failed  (${DURATION}s)"
  echo ""
  dim   "  Query logs from durable storage:"
  dim   "    ./scripts/query-run.sh ${RUN_NAME} --logs"
fi
echo ""