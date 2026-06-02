<!-- Cluster level -->

kubectl patch configmap feature-flags \
  -n tekton-pipelines \
  --type merge \
  -p '{"data":{"coschedule":"disabled"}}'


<!-- Machine level -->
sudo apt update && sudo apt install -y nfs-kernel-server nfs-common
sudo mkdir -p /srv/nfs/buildah-cache
sudo chown nobody:nogroup /srv/nfs/buildah-cache
sudo chmod 777 /srv/nfs/buildah-cache


KIND_SUBNET=$(docker network inspect kind --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}' | grep -oP '[\d.]+/\d+')
echo $KIND_SUBNET
# should be: 172.18.0.0/16

echo "/srv/nfs/buildah-cache ${KIND_SUBNET}(rw,sync,no_subtree_check,no_root_squash)" | sudo tee /etc/exports
sudo exportfs -ra
sudo exportfs -v
sudo systemctl enable --now nfs-kernel-server


# check it 
docker exec $(kind get nodes --name 6d4418a8-c7d1-487a-b5d3-ec0ea9609cc7 | head -1) showmount -e 172.18.0.1
