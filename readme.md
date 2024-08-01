
deploy your app and service and map the service in ingress file

https://artifacthub.io/packages/helm/ingress-nginx/ingress-nginx

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx


helm install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx -f nginx-value.yaml 

then add ignress
kubectl apply -f ingress.yaml


https://artifacthub.io/packages/helm/cert-manager/cert-manager

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.15.2/cert-manager.crds.yaml

Add the Jetstack Helm repository
$ helm repo add jetstack https://charts.jetstack.io --force-update

helm install cert-manager -n cert-manager --version v1.15.2 jetstack/cert-manager -f cert-manager-values.yaml

then add issuer
kubectl apply -f issuer.yaml