
Create it

  kubectl create secret generic platform-secrets \
  --from-literal=JWT_SECRET=1234 \
  --from-literal=ANOTHER_KEY=value


verify it : 

  kubectl get secret platform-secrets \
  -o jsonpath="{.data.JWT_SECRET}" | base64 -d

update it : 

  kubectl delete secret platform-secrets

  kubectl create secret generic platform-secrets \
    --from-literal=JWT_SECRET=1234 \
    --from-literal=ANOTHER_KEY=value