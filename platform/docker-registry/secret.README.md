kubectl create secret generic registry-auth-secret \
  --from-file=auth.cert=./auth.cert \
  --dry-run=client -o yaml | kubectl apply -f -



  kubectl create secret generic registry-ui-secrets \
  --from-literal=REGISTRY_USER="__token__" \
  --from-literal=REGISTRY_PASS="......" \
  --dry-run=client -o yaml | kubectl apply -f -