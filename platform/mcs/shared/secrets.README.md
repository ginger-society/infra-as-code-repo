
Create it

  kubectl create secret generic platform-secrets \
  --from-literal=JWT_SECRET={{values.JWT_TOKEN}} \
  --from-literal=ANOTHER_KEY=value


verify it : 

  kubectl get secret platform-secrets \
  -o jsonpath="{.data.JWT_SECRET}" | base64 -d

update it : 

  kubectl delete secret platform-secrets

  kubectl create secret generic platform-secrets \
    --from-literal=JWT_SECRET=1234 \
    --from-literal=ANOTHER_KEY=value



kubectl create secret generic ses-credentials \
  --from-literal=AWS_ACCESS_KEY_ID=your_key \
  --from-literal=AWS_SECRET_ACCESS_KEY=your_secret \
  --dry-run=client -o yaml | kubectl apply -f -