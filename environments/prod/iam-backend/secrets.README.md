kubectl create secret generic iam-service-api-secrets \
  --from-literal=ISC_SECRET=verysecure \
  --from-literal=ROCKET_SECRET_KEY="$(openssl rand -base64 64 | tr -d '\n')" \
  --from-literal=DATABASE_URL="postgresql://postgres:YOUR_PASSWORD@pg-postgresql:5432/iam-db" \
  --dry-run=client -o yaml | kubectl apply -f -



  update using : 

  kubectl create secret generic iam-service-api-secrets \
  --from-literal=ISC_SECRET=verysecure \
  --from-literal=ROCKET_SECRET_KEY="$(openssl rand -base64 64 | tr -d '\n')" \
  --dry-run=client -o yaml | kubectl apply -f -

