kubectl create secret generic metadata-service-api-secrets \
  --from-literal=ISC_SECRET=supersecret \
  --from-literal=ROCKET_SECRET_KEY="$(openssl rand -base64 64 | tr -d '\n')" \
  --from-literal=DATABASE_URL="postgresql://postgres:$(kubectl get secret pg-postgresql -o jsonpath='{.data.postgres-password}' | base64 -d)@pg-postgresql:5432/metadata-db" \
  --dry-run=client -o yaml | kubectl apply -f -