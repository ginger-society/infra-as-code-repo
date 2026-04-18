helm install my-rabbitmq . \
  --set rabbitmq.auth.username=myuser \
  --set rabbitmq.auth.password=mypass



kubectl get secret my-rabbitmq-rabbitmq-auth -o yaml

kubectl get secret my-rabbitmq-rabbitmq-auth -o jsonpath="{.data.url}" | base64 -d