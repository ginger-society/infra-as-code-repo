helm install pg bitnami/postgresql -f postgress-resource-config.yml

helm upgrade pg bitnami/postgresql -f postgress-resource-config.yml

then get password using : 

    kubectl get secret pg-postgresql \
  -o jsonpath="{.data.postgres-password}" | base64 -d



for pgadmin : 

helm repo add runix https://helm.runix.net
helm repo update

helm install pgadmin runix/pgadmin4 \
  -f pgadmin-config.yml \
  --set env.email=admin@gingersociety.org \
  --set env.password='password here'



to load backup files : 

kubectl exec -i pg-postgresql-0 -- \
  env PGPASSWORD=$(kubectl get secret pg-postgresql \
    -o jsonpath="{.data.postgres-password}" | base64 -d) \
  psql -U postgres -d metadata-db < metadata-db.sql
