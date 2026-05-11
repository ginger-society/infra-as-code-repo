#!/bin/bash

# ── Args ──────────────────────────────────────────────────────────────────────
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <cluster-name> <api-port> <port-mappings-json>"
    echo "Example: $0 alpha 8001 '[{\"container_port\":80,\"host_port\":8081,\"protocol\":\"TCP\"}]'"
    exit 1
fi

CLUSTER_NAME="$1"
API_PORT="$2"
PORT_MAPPINGS_JSON="$3"
FQDN="${CLUSTER_NAME}.test-clusters.rackmint.com"
KIND_CONFIG="/tmp/kind-${CLUSTER_NAME}.yaml"
NGINX_ENTRIES_FILE="/etc/nginx/stream.d/kind-cluster-entries.map"
NGINX_STREAM_CONF="/etc/nginx/stream.d/kind-clusters.conf"

# ── Check jq is available ─────────────────────────────────────────────────────
if ! command -v jq &>/dev/null; then
    apt-get install -y jq -q
fi

# ── Check if cluster already exists ───────────────────────────────────────────
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    echo "ERROR: cluster '${CLUSTER_NAME}' already exists"
    exit 2
fi

# ── Build extraPortMappings yaml ──────────────────────────────────────────────
PORT_MAPPINGS_YAML=""
while IFS= read -r mapping; do
    container_port=$(echo "$mapping" | jq -r '.container_port')
    host_port=$(echo "$mapping" | jq -r '.host_port')
    protocol=$(echo "$mapping" | jq -r '.protocol // "TCP"')
    PORT_MAPPINGS_YAML="${PORT_MAPPINGS_YAML}  - containerPort: ${container_port}
    hostPort: ${host_port}
    protocol: ${protocol}
"
done < <(echo "$PORT_MAPPINGS_JSON" | jq -c '.[]')

# ── Write Kind config ─────────────────────────────────────────────────────────
cat > "$KIND_CONFIG" <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ${CLUSTER_NAME}

networking:
  apiServerAddress: "0.0.0.0"
  apiServerPort: ${API_PORT}

nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: ClusterConfiguration
    apiServer:
      certSANs:
      - ${FQDN}
      - 127.0.0.1
      - localhost
  extraPortMappings:
${PORT_MAPPINGS_YAML}
EOF

# ── Create cluster ────────────────────────────────────────────────────────────
echo "Creating kind cluster '${CLUSTER_NAME}'..."
kind create cluster --config "$KIND_CONFIG"
if [ $? -ne 0 ]; then
    echo "ERROR: kind create cluster failed"
    rm -f "$KIND_CONFIG"
    exit 3
fi

rm -f "$KIND_CONFIG"

# ── Update Nginx stream config ────────────────────────────────────────────────
mkdir -p /etc/nginx/stream.d

# Update entries file (.map extension so nginx doesn't include it)
touch "$NGINX_ENTRIES_FILE"
sed -i "/^.*${FQDN}.*$/d" "$NGINX_ENTRIES_FILE"
echo "        ${FQDN}    127.0.0.1:${API_PORT};" >> "$NGINX_ENTRIES_FILE"

# Rebuild stream conf from entries
cat > "$NGINX_STREAM_CONF" <<EOF
map \$ssl_preread_server_name \$kind_backend {
$(cat "$NGINX_ENTRIES_FILE")
}

server {
    listen 3333;
    ssl_preread on;
    proxy_pass \$kind_backend;
}
EOF

nginx -t && systemctl reload nginx
if [ $? -ne 0 ]; then
    echo "ERROR: nginx reload failed"
    exit 4
fi

# ── Get kubeconfig and replace server hostname ────────────────────────────────
KUBECONFIG=$(kind get kubeconfig --name "${CLUSTER_NAME}" 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "ERROR: failed to get kubeconfig"
    exit 5
fi

KUBECONFIG=$(echo "$KUBECONFIG" | sed "s|server: https://0\.0\.0\.0:${API_PORT}|server: https://${FQDN}:3333|g")
KUBECONFIG=$(echo "$KUBECONFIG" | sed "s|server: https://127\.0\.0\.1:${API_PORT}|server: https://${FQDN}:3333|g")

echo "KUBECONFIG_START"
echo "$KUBECONFIG"
echo "KUBECONFIG_END"

# ── Save kubeconfig ───────────────────────────────────────────────────────────
KUBE_DIR="${HOME}/.kube"
mkdir -p "$KUBE_DIR"

echo "$KUBECONFIG" > "${KUBE_DIR}/${CLUSTER_NAME}.yaml"
chmod 600 "${KUBE_DIR}/${CLUSTER_NAME}.yaml"

echo "Kubeconfig saved to ${KUBE_DIR}/${CLUSTER_NAME}.yaml"
echo "Use it with: kubectl --kubeconfig=${KUBE_DIR}/${CLUSTER_NAME}.yaml get nodes"
echo "Or export:   export KUBECONFIG=${KUBE_DIR}/${CLUSTER_NAME}.yaml"