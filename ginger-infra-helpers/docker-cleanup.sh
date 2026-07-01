#!/bin/bash
# docker-cleanup.sh
# Usage: ./docker-cleanup.sh [--clean] [--host-only] [--kind-only]

set -euo pipefail

DRY_RUN=true
HOST_ONLY=false
KIND_ONLY=false

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

for arg in "$@"; do
  case $arg in
    --clean)     DRY_RUN=false ;;
    --host-only) HOST_ONLY=true ;;
    --kind-only) KIND_ONLY=true ;;
  esac
done

if $DRY_RUN; then
  echo -e "${YELLOW}=== DRY RUN MODE — nothing will be deleted ===${NC}"
  echo -e "${YELLOW}    Run with --clean to actually delete${NC}\n"
else
  echo -e "${RED}=== CLEAN MODE — data will be permanently deleted ===${NC}\n"
fi

# ─────────────────────────────────────────────
# Size parser: handles MB, GB, kB
# ─────────────────────────────────────────────
parse_size_to_mb() {
  echo "$1" | awk '{
    val = $1
    if (val ~ /GB/) { gsub(/GB/, "", val); printf "%.1f", val * 1024 }
    else if (val ~ /MB/) { gsub(/MB/, "", val); printf "%.1f", val }
    else if (val ~ /kB/) { gsub(/kB/, "", val); printf "%.1f", val / 1024 }
    else { printf "0" }
  }'
}

# ─────────────────────────────────────────────
# Host Docker cleanup
# ─────────────────────────────────────────────
cleanup_host_docker() {
  echo -e "${BLUE}━━━ Host Docker ━━━${NC}"
  docker system df | sed 's/^/  /'
  echo ""

  if ! $DRY_RUN; then
    echo -e "  ${RED}Cleaning...${NC}"
    docker container prune -f
    docker image prune -a -f
    docker volume prune -f
    docker builder prune -a -f
    echo ""
    echo -e "  ${GREEN}After cleanup:${NC}"
    docker system df | sed 's/^/  /'
  fi
  echo ""
}

# ─────────────────────────────────────────────
# Kind node cleanup — proper in-use diffing
# ─────────────────────────────────────────────
cleanup_kind_node() {
  local node="$1"
  echo -e "${BLUE}━━━ Kind node: $node ━━━${NC}"

  # All images: columns are REPO, TAG, ID, SIZE
  local all_images
  all_images=$(docker exec "$node" crictl images 2>/dev/null | tail -n +2)

  # Image IDs currently in use by running containers
  local used_ids
  used_ids=$(docker exec "$node" crictl ps 2>/dev/null \
    | tail -n +2 \
    | awk '{print $2}' \
    | sort -u)

  local total_images
  total_images=$(echo "$all_images" | grep -c . || true)

  local unused_images=""
  local unused_count=0
  local reclaimable_mb=0

  while IFS= read -r line; do
    [ -z "$line" ] && continue

    local repo tag image_id size
    repo=$(echo "$line"    | awk '{print $1}')
    tag=$(echo "$line"     | awk '{print $2}')
    image_id=$(echo "$line" | awk '{print $3}')
    size=$(echo "$line"    | awk '{print $4, $5}' | tr -d ' ')

    # Check if this image ID is in the used set
    local in_use=false
    while IFS= read -r used_id; do
      # crictl ps IMAGE column is a prefix of the full ID
      if [[ "$image_id" == "$used_id"* ]] || [[ "$used_id" == "$image_id"* ]]; then
        in_use=true
        break
      fi
    done <<< "$used_ids"

    if ! $in_use; then
      unused_images="${unused_images}\n${line}"
      unused_count=$((unused_count + 1))
      local mb
      mb=$(parse_size_to_mb "$size")
      reclaimable_mb=$(echo "$reclaimable_mb $mb" | awk '{printf "%.1f", $1 + $2}')
    fi
  done <<< "$all_images"

  echo -e "  Total images:      ${total_images}"
  echo -e "  In use:            $((total_images - unused_count))"
  echo -e "  ${YELLOW}Unused:            ${unused_count} (~${reclaimable_mb} MB reclaimable)${NC}"

  if [ "$unused_count" -gt 0 ]; then
    echo ""
    echo -e "  ${CYAN}Unused images (safe to delete):${NC}"
    echo -e "$unused_images" | grep -v '^$' | \
      awk '{printf "    %-70s  tag=%-10s  %s %s\n", $1, $2, $4, $5}'
  fi

  if ! $DRY_RUN && [ "$unused_count" -gt 0 ]; then
    echo ""
    echo -e "  ${RED}Removing unused images...${NC}"
    echo -e "$unused_images" | grep -v '^$' | awk '{print $3}' | while read -r id; do
      docker exec "$node" crictl rmi "$id" 2>/dev/null \
        && echo -e "  ${GREEN}✓ Removed $id${NC}" \
        || echo -e "  ${YELLOW}⚠ Skipped $id (may be in use or already gone)${NC}"
    done
  fi

  echo ""
}

# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────
if ! $KIND_ONLY; then
  cleanup_host_docker
fi

if ! $HOST_ONLY; then
  KIND_CONTAINERS=$(docker ps --format "{{.Names}}" \
    | grep -E "control-plane|worker" || true)

  if [ -z "$KIND_CONTAINERS" ]; then
    echo -e "${YELLOW}No Kind cluster nodes found.${NC}"
  else
    while IFS= read -r node; do
      cleanup_kind_node "$node"
    done <<< "$KIND_CONTAINERS"
  fi
fi

# ─────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────
echo -e "${BLUE}━━━ Disk Summary ━━━${NC}"
df -h / | tail -1 | awk '{printf "  Root filesystem: %s used of %s (%s)\n", $3, $2, $5}'
docker info 2>/dev/null | grep "Docker Root Dir" \
  | awk '{printf "  Docker root dir: %s\n", $NF}' || true
echo ""

if $DRY_RUN; then
  echo -e "${YELLOW}Re-run with --clean to reclaim the space above.${NC}"
fi