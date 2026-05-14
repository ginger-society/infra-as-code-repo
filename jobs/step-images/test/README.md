

kubectl create secret generic ginger-token-secret \
  --from-literal=token=API_TOKEN \
  -n tasks-PROJECTNAME-provisioner-service


kubectl delete pvc general-purpose-cache-pvc -n tasks-PROJECTNAME-provisioner-service


kubectl create -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: general-purpose-cache-pvc
  namespace: tasks-PROJECTNAME-provisioner-service
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi
EOF


kubectl create -f - <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: buildah-cache-pv
spec:
  capacity:
    storage: 100Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""
  nfs:
    server: 172.18.0.1
    path: /srv/nfs/buildah-cache
EOF

kubectl create -f - <<EOF
# ── PersistentVolumeClaim ─────────────────────────────────────────────────────
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: buildah-cache-pvc
  namespace: tasks-PROJECTNAME-provisioner-service
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 100Gi
  storageClassName: ""
  volumeName: buildah-cache-pv

EOF


kubectl patch configmap feature-flags \
  -n tekton-pipelines \
  --type merge \
  -p '{"data":{"coschedule":"disabled"}}'