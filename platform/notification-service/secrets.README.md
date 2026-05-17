kubectl create secret generic ses-credentials \
  --from-literal=AWS_ACCESS_KEY_ID=your_key \
  --from-literal=AWS_SECRET_ACCESS_KEY=your_secret \
  --dry-run=client -o yaml | kubectl apply -f -