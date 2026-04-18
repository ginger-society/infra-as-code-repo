kubectl create secret generic iam-service-api-secrets \
  --from-literal=ISC_SECRET=verysecure \
  --from-literal=ROCKET_SECRET_KEY="$(openssl rand -base64 64 | tr -d '\n')" \
  --dry-run=client -o yaml | kubectl apply -f -



  update using : 

  kubectl create secret generic iam-service-api-secrets \
  --from-literal=ISC_SECRET=verysecure \
  --from-literal=ROCKET_SECRET_KEY="$(openssl rand -base64 64 | tr -d '\n')" \
  --dry-run=client -o yaml | kubectl apply -f -