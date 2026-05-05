kubectl create secret generic registry-auth-secret \
  --from-file=auth.cert=./auth.cert \
  --dry-run=client -o yaml | kubectl apply -f -