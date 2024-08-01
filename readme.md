# This is the repo for API services deployed on api.gingersociety.org


## There is only one env as of now : staging

This is deployed on api-staging.gingersociety.org

Common code related to this env is available in staging directory
There are few apps deployed

1. **example-app**

    This is a sample hello world service

    Available on api-staging.gingersociety.org/test/*
2. **iam-service-api**

    This is the deployment for IAM service apis

    Available on api-staging.gingersociety.org/iam-service/*
3. **metadata-service-api**

    This is the deployment for Metadata service apis

    Available on api-staging.gingersociety.org/metadata-service/*


## Notes we took while creating this repo

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