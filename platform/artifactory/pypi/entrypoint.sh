#!/usr/bin/env bash
set -uo pipefail

# ── Config (env vars) ────────────────────────────────────────────────────────
# SYNC_PACKAGES     comma-separated list of package name prefixes to publish,
#                   e.g. "ginger_dj_framework,another_pkg"
# PACKAGES_DIR       where pypiserver stores its files (mounted PVC path)
# SLEEP_SECONDS      how long to wait between sync runs
# TWINE_USERNAME     should be "__token__" if using an API token
# TWINE_PASSWORD     the token/password itself (from a Secret)
# DRY_RUN            if "true", logs what would be uploaded but does not call twine
SYNC_PACKAGES="${SYNC_PACKAGES:-}"
PACKAGES_DIR="${PACKAGES_DIR:-/data/packages}"
SLEEP_SECONDS="${SLEEP_SECONDS:-3600}"
DRY_RUN="${DRY_RUN:-false}"
LOCK_FILE="/tmp/pypi-sync.lock"
STAGING_DIR="/tmp/staging"

log() {
  echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] $*"
}

require_env() {
  if [ -z "${SYNC_PACKAGES}" ]; then
    log "ERROR: SYNC_PACKAGES is not set. Refusing to start."
    exit 1
  fi
  if [ "${DRY_RUN}" != "true" ]; then
    if [ -z "${TWINE_USERNAME:-}" ] || [ -z "${TWINE_PASSWORD:-}" ]; then
      log "ERROR: TWINE_USERNAME/TWINE_PASSWORD must be set unless DRY_RUN=true."
      exit 1
    fi
  fi
}

# Turn "pkgA,pkgB" into an array, trimming whitespace.
package_list() {
  IFS=',' read -ra RAW <<< "${SYNC_PACKAGES}"
  for p in "${RAW[@]}"; do
    echo "${p}" | xargs
  done
}

run_sync() {
  log "Starting sync run."
  rm -rf "${STAGING_DIR}"
  mkdir -p "${STAGING_DIR}"

  local found_any=false

  while IFS= read -r pkg; do
    [ -z "${pkg}" ] && continue

    # Only match real distribution files for this package name, never the
    # pypiserver .metadata.json sidecar files it also writes to this dir.
    # Package filenames on PyPI normalize hyphens/underscores/dots, so match
    # loosely on a normalized prefix followed by a version-looking separator.
    local normalized
    normalized=$(echo "${pkg}" | tr '-' '_')

    shopt -s nullglob
    local matches=()
    for f in "${PACKAGES_DIR}"/*; do
      local base
      base=$(basename "${f}")
      case "${base}" in
        *.whl|*.tar.gz) ;;
        *) continue ;;
      esac
      local base_normalized
      base_normalized=$(echo "${base}" | tr '-' '_')
      if [[ "${base_normalized}" == "${normalized}"-* ]] || [[ "${base_normalized}" == "${normalized}"_* ]]; then
        matches+=("${f}")
      fi
    done
    shopt -u nullglob

    if [ "${#matches[@]}" -eq 0 ]; then
      log "No files found for package '${pkg}', skipping."
      continue
    fi

    for m in "${matches[@]}"; do
      log "Staging $(basename "${m}") for package '${pkg}'."
      cp "${m}" "${STAGING_DIR}/"
      found_any=true
    done
  done < <(package_list)

  if [ "${found_any}" = false ]; then
    log "Nothing to publish this run."
    return 0
  fi

  if [ "${DRY_RUN}" = "true" ]; then
    log "DRY_RUN=true, would have uploaded:"
    ls -1 "${STAGING_DIR}"
    return 0
  fi

  log "Uploading staged files with twine (--skip-existing)."
  if twine upload --skip-existing "${STAGING_DIR}"/*; then
    log "Upload run completed successfully."
  else
    log "ERROR: twine upload failed. See output above."
    return 1
  fi
}

main() {
  require_env
  log "pypi-public-sync starting. Packages=[${SYNC_PACKAGES}] interval=${SLEEP_SECONDS}s dry_run=${DRY_RUN}"

  while true; do
    (
      flock -n 9 || { log "Previous sync still running, skipping this cycle."; exit 0; }
      run_sync
    ) 9>"${LOCK_FILE}"

    log "Sleeping ${SLEEP_SECONDS}s until next run."
    sleep "${SLEEP_SECONDS}"
  done
}

main