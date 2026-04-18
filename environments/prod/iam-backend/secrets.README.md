kubectl create secret generic iam-service-api-secrets \
  --from-literal=ISC_SECRET=verysecure \
  --from-literal=ROCKET_SECRET_KEY=supersecret



  update using : 

  kubectl create secret generic iam-service-api-secrets \
  --from-literal=ISC_SECRET=verysecure \
  --from-literal=ROCKET_SECRET_KEY=supersecret \
  --dry-run=client -o yaml | kubectl apply -f -