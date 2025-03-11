#!/bin/sh

export PATH=$PATH:/usr/local/bin
export KUBECONFIG=/keys/kubeconfig.gingersociety.prod.yml

# Extract Gitolite environment variables
GL_USER="$GL_USER"
GL_REPO="$GL_REPO"


# Gitolite provides ref updates via stdin (oldrev newrev refname)
read GL_OLDREV GL_NEWREV GL_REFNAME

# Generate UUID for the TaskRun
UUID=$(uuidgen)

# Create a TaskRun YAML file
cat <<EOF | /usr/local/bin/kubectl apply -f -
apiVersion: tekton.dev/v1beta1
kind: TaskRun
metadata:
  name: hello-world-run-${UUID}
spec:
  taskRef:
    name: hello-world
  workspaces:
    - name: source
      emptyDir: {}  # Temporary in-memory storage
    - name: ssh-credentials
      secret:
        secretName: ssh-private-key  # Reference to your SSH private key secret
    - name: ssh-config
      emptyDir: {}  # Shared space for SSH setup (fixes the error)
    - name: kubeconfig  # Mount kubeconfig from existing PVC
      persistentVolumeClaim:
        claimName: gitolite-pvc
      subPath: kubeconfigs  # Use the 'kubeconfigs' sub-directory
  params:
    - name: GL_USER
      value: "${GL_USER}"
    - name: GL_REPO
      value: "${GL_REPO}"
    - name: GL_REFNAME
      value: "${GL_REFNAME}"
    - name: GL_OLDREV
      value: "${GL_OLDREV}"
    - name: GL_NEWREV
      value: "${GL_NEWREV}"
EOF