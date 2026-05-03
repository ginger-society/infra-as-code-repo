# Create secret from your actual file
kubectl create secret generic gitolite-admin-key \
  --from-file=admin_key.pub=./admin_key.pub