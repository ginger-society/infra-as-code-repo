kubectl create secret generic verdaccio-secrets \
  --from-literal=JWT_SECRET_KEY=1234 \
  --dry-run=client -o yaml | kubectl apply -f -