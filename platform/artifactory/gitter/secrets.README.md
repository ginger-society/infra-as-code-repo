kubectl create secret generic gitolite-admin-key \
  --from-file=admin_key.pub=./admin_key.pub \
  --from-file=admin_key=./admin_key \
  --from-file=gh_ssh_key=./backup_account_ssh_key \
  --from-literal=gh_pat="$(cat ./backup_account_pat)" \
  --dry-run=client -o yaml | kubectl apply -f -


  kubectl create configmap ginger-gitter-config \
  --from-literal=GH_SSH_PREFIX="git@github.com:NAME" \
  --from-literal=GH_USERNAME="NAME" \
  --dry-run=client -o yaml | kubectl apply -f -