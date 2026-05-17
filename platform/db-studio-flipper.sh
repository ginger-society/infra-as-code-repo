kubectl scale deployment metadata-db-runtime --replicas=1
kubectl scale deployment iam-db-runtime --replicas=1
kubectl scale deployment pgadmin-pgadmin4 --replicas=0
kubectl scale deployment example-deploy --replicas=0
