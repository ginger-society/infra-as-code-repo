#!/usr/bin/env bash
set -uo pipefail

# ── Config (env vars) ────────────────────────────────────────────────────────
# SYNC_PACKAGES   comma-separated list of full package names (including scope),
#                 e.g. "@gingersociety/ginger-ui,@gingersociety/other-pkg"
# STORAGE_DIR     verdaccio storage root (mounted PVC path), default below
#                 matches verdaccio's own layout: <STORAGE_DIR>/<pkg>/*.tgz
# SLEEP_SECONDS   how long to wait between sync runs
# NPM_TOKEN       npm automation/publish token for registry.npmjs.org
# DRY_RUN         if "true", logs what would be published but does not publish
SYNC_PACKAGES="${SYNC_PACKAGES:-}"
STORAGE_DIR="${STORAGE_DIR:-/verdaccio/storage}"
SLEEP_SECONDS="${SLEEP_SECONDS:-3600}"
DRY_RUN="${DRY_RUN:-false}"
LOCK_FILE="/tmp/npm-sync.lock"
STAGING_DIR="/tmp/staging"
NPMRC_FILE="${HOME}/.npmrc"

log() {
  echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] $*"
}

require_env() {
  if [ -z "${SYNC_PACKAGES}" ]; then
    log "ERROR: SYNC_PACKAGES is not set. Refusing to start."
    exit 1
  fi
  if [ "${DRY_RUN}" != "true" ] && [ -z "${NPM_TOKEN:-}" ]; then
    log "ERROR: NPM_TOKEN must be set unless DRY_RUN=true."
    exit 1
  fi
}

write_npmrc() {
  if [ "${DRY_RUN}" = "true" ]; then
    return 0
  fi
  cat > "${NPMRC_FILE}" <<EOF
//registry.npmjs.org/:_authToken=${NPM_TOKEN}
registry=https://registry.npmjs.org/
EOF
  chmod 600 "${NPMRC_FILE}"
}

package_list() {
  IFS=',' read -ra RAW <<< "${SYNC_PACKAGES}"
  for p in "${RAW[@]}"; do
    echo "${p}" | xargs
  done
}

# Returns 0 if <pkg>@<version> already exists on the public registry.
version_exists() {
  local pkg="$1"
  local version="$2"
  npm view "${pkg}@${version}" version --registry https://registry.npmjs.org/ >/dev/null 2>&1
}

publish_one() {
  local tgz="$1"
  local pkg="$2"

  # Pull the version straight out of the tarball's package.json rather than
  # trying to parse it from the filename, since scoped names contain
  # hyphens that make filename parsing ambiguous.
  local version
  version=$(tar -xOzf "${tgz}" package/package.json 2>/dev/null | node -pe 'JSON.parse(require("fs").readFileSync(0)).version' 2>/dev/null)

  if [ -z "${version}" ]; then
    log "WARN: could not read version from $(basename "${tgz}"), skipping."
    return 0
  fi

  if [ "${DRY_RUN}" = "true" ]; then
    log "DRY_RUN: would check/publish ${pkg}@${version} from $(basename "${tgz}")."
    return 0
  fi

  if version_exists "${pkg}" "${version}"; then
    log "${pkg}@${version} already published, skipping."
    return 0
  fi

  log "Publishing ${pkg}@${version} from $(basename "${tgz}")."
  local out
  if out=$(npm publish "${tgz}" --access public --registry https://registry.npmjs.org/ 2>&1); then
    log "Published ${pkg}@${version} successfully."
  else
    if echo "${out}" | grep -qi "cannot publish over"; then
      log "${pkg}@${version} was published concurrently by another process, skipping."
    else
      log "ERROR: npm publish failed for ${pkg}@${version}:"
      echo "${out}"
      return 1
    fi
  fi
}

run_sync() {
  log "Starting sync run."
  write_npmrc

  local had_error=false

  while IFS= read -r pkg; do
    [ -z "${pkg}" ] && continue

    local pkg_dir="${STORAGE_DIR}/${pkg}"
    if [ ! -d "${pkg_dir}" ]; then
      log "No storage directory found for '${pkg}' at ${pkg_dir}, skipping."
      continue
    fi

    shopt -s nullglob
    local tarballs=("${pkg_dir}"/*.tgz)
    shopt -u nullglob

    if [ "${#tarballs[@]}" -eq 0 ]; then
      log "No .tgz files found for '${pkg}', skipping."
      continue
    fi

    for tgz in "${tarballs[@]}"; do
      publish_one "${tgz}" "${pkg}" || had_error=true
    done
  done < <(package_list)

  if [ "${had_error}" = true ]; then
    return 1
  fi
}

main() {
  require_env
  log "npm-public-sync starting. Packages=[${SYNC_PACKAGES}] interval=${SLEEP_SECONDS}s dry_run=${DRY_RUN}"

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