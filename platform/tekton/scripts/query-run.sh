#!/usr/bin/env bash
# =============================================================
# query-run.sh — Query past pipeline runs from durable storage
#
# Queries PostgreSQL (metadata) and Loki (logs) directly.
# Works even after pods and PipelineRuns have been deleted.
#
# Usage:
#   scripts/query-run.sh --list                  list all stored runs
#   scripts/query-run.sh <run-name>              metadata + logs
#   scripts/query-run.sh <run-name> --meta       metadata only
#   scripts/query-run.sh <run-name> --logs       logs only
# =============================================================

# Enforce bash — sh does not handle the python3 inline -c quoting correctly
# 'sh script.sh' passes the script to sh directly, bypassing the shebang,
# so we detect it and re-exec under bash explicitly.
if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
  exit $?
fi
# If exec failed (bash not found), error clearly
command -v bash >/dev/null 2>&1 || { echo "Error: bash is required"; exit 1; }

set -euo pipefail

# ── Config ────────────────────────────────────────────────────
PG_NS="tekton-pipelines"
PG_POD="tekton-results-postgres-0"
PG_USER="tekton"
PG_PASS="tekton-results-secret"
PG_DB="tekton-results"
LOKI_NS="logging"
LOKI_POD="loki-0"
LOKI_LOOKBACK_DAYS=31

# ── Helpers ───────────────────────────────────────────────────
bold() { printf '\033[1m%s\033[0m\n' "$*"; }
hr()   { printf '%.0s─' {1..60}; echo; }

pg() {
  kubectl exec -n "${PG_NS}" "${PG_POD}" -- \
    env PGPASSWORD="${PG_PASS}" \
    psql -U "${PG_USER}" -d "${PG_DB}" \
    --no-align --tuples-only -c "$1" 2>/dev/null
}

loki_query() {
  local query="$1" limit="${2:-1000}"
  local encoded now_ns start_ns
  encoded=$(python3 -c \
    "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$query")
  now_ns=$(python3 -c "import time; print(int(time.time()*1e9))")
  start_ns=$(python3 -c \
    "import time; print(int((time.time() - ${LOKI_LOOKBACK_DAYS}*86400)*1e9))")
  kubectl exec -n "${LOKI_NS}" "${LOKI_POD}" -- \
    wget -qO- \
    "http://localhost:3100/loki/api/v1/query_range?query=${encoded}&limit=${limit}&start=${start_ns}&end=${now_ns}&direction=forward" \
    2>/dev/null || true
}

parse_logs() {
  # Receives JSON on stdin, run-name as $1
  # Written as a separate function to avoid heredoc/sh conflicts
  local run="$1"
  python3 -c "
import sys, json, datetime, re

run_name = '$run'
raw = sys.stdin.read().strip()

if not raw:
    print('  Loki returned an empty response.')
    sys.exit(0)

try:
    # Remove control characters that break json.loads (e.g. raw \r from git progress)
    raw_clean = re.sub(r'[\x00-\x08\x0b\x0c\x0e-\x1f]', '', raw)
    d = json.loads(raw_clean)
except json.JSONDecodeError as e:
    print(f'  Could not parse Loki response: {e}')
    print(f'  Response starts with: {raw[:200]!r}')
    sys.exit(0)

results = d.get('data', {}).get('result', [])
if not results:
    print(f'  No log streams found for pipelinerun={run_name}')
    sys.exit(0)

# Sort streams by first log entry timestamp
results.sort(key=lambda s: s['values'][0][0] if s['values'] else '0')

for stream in results:
    pod = stream['stream'].get('pod', '?')
    ctr = stream['stream'].get('container', '?')
    task = stream['stream'].get('task', '')
    header = f'  ┌─ {pod}  /  {ctr}'
    if task:
        header += f'  [{task}]'
    print(header)
    for ts_ns, line in stream['values']:
        t = datetime.datetime.utcfromtimestamp(
            int(ts_ns) / 1e9
        ).strftime('%H:%M:%S')
        # Keep only the last segment after carriage returns (git progress lines)
        line = line.split('\r')[-1].strip()
        if line:
            print(f'  │ {t}  {line}')
    print('  └─')
    print()
"
}

# ── List all stored runs ──────────────────────────────────────
list_runs() {
  bold "\n  All stored runs (PostgreSQL)\n"
  printf "  %-14s  %-19s  %s\n" "TYPE" "CREATED (UTC)" "UUID"
  hr
  pg "SELECT type, created_time, name
      FROM records
      ORDER BY created_time DESC
      LIMIT 100;" \
  | while IFS='|' read -r type ts name; do
      type=$(echo "$type" | xargs)
      ts=$(echo "$ts" | xargs | cut -c1-19)
      name=$(echo "$name" | xargs)
      case "$type" in
        *PipelineRun) label="PipelineRun" ;;
        *TaskRun)     label="  TaskRun  " ;;
        *)            label="$type" ;;
      esac
      printf "  %-14s  %-19s  %s\n" "$label" "$ts" "$name"
    done
  echo ""
}

# ── Metadata ─────────────────────────────────────────────────
show_metadata() {
  local run="$1"
  bold "\n  Metadata — ${run}\n"

  echo "  PipelineRun record:"
  hr
  pg "SELECT name, created_time, updated_time
      FROM records
      WHERE type = 'tekton.dev/v1.PipelineRun'
      ORDER BY created_time DESC
      LIMIT 1;" \
  | while IFS='|' read -r uuid created updated; do
      echo "  UUID:     $(echo "$uuid" | xargs)"
      echo "  Started:  $(echo "$created" | xargs | cut -c1-19) UTC"
      echo "  Updated:  $(echo "$updated" | xargs | cut -c1-19) UTC"
    done

  echo ""
  echo "  TaskRun records (most recent run):"
  hr
  printf "  %-36s  %-19s  %s\n" "UUID" "CREATED (UTC)" "TYPE"
  pg "SELECT name, created_time, type
      FROM records
      WHERE type = 'tekton.dev/v1.TaskRun'
      ORDER BY created_time DESC
      LIMIT 3;" \
  | while IFS='|' read -r name ts type; do
      printf "  %-36s  %-19s  %s\n" \
        "$(echo "$name" | xargs)" \
        "$(echo "$ts"   | xargs | cut -c1-19)" \
        "$(echo "$type" | xargs)"
    done

  echo ""
  echo "  Results entries:"
  hr
  pg "SELECT name, created_time
      FROM results
      ORDER BY created_time DESC
      LIMIT 5;" \
  | while IFS='|' read -r name ts; do
      echo "  $(echo "$ts" | xargs | cut -c1-19)  $(echo "$name" | xargs)"
    done
  echo ""
}

# ── Logs ─────────────────────────────────────────────────────
show_logs() {
  local run="$1"
  bold "\n  Logs — ${run}  (Loki, last ${LOKI_LOOKBACK_DAYS} days)\n"
  local raw
  raw=$(loki_query "{pipelinerun=\"${run}\"}" 1000)
  echo "$raw" | parse_logs "$run"
}

# ── Main ─────────────────────────────────────────────────────
case "${1:-}" in
  --list|-l)
    list_runs
    ;;
  "")
    bold "Usage:"
    echo "  $0 --list"
    echo "  $0 <run-name>"
    echo "  $0 <run-name> --meta"
    echo "  $0 <run-name> --logs"
    exit 1
    ;;
  *)
    RUN="$1"
    MODE="${2:-both}"
    case "$MODE" in
      --meta|-m) show_metadata "$RUN" ;;
      --logs|-l) show_logs "$RUN" ;;
      both|"")
        show_metadata "$RUN"
        show_logs "$RUN"
        ;;
      *)
        echo "Unknown option: $MODE"
        exit 1
        ;;
    esac
    ;;
esac