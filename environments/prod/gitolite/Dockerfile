FROM jgiannuzzi/gitolite

# Use a newer Alpine version
RUN apk add --no-cache wget bash
RUN apk add util-linux
# Install kubectl using wget
RUN wget -qO /usr/local/bin/kubectl "https://dl.k8s.io/release/$(wget -qO- https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x /usr/local/bin/kubectl

# Ensure required directories exist
RUN mkdir -p /keys /nfs/kubeconfigs

# Set the working directory
WORKDIR /var/lib/git
COPY create-tekton-task-run.sh /var/lib/git/trigger-tekton-task.sh

# Add the Gitolite post-receive hook
RUN mkdir -p /var/lib/git/.gitolite/hooks/common && \
    echo '#!/bin/sh' > /var/lib/git/.gitolite/hooks/common/post-receive && \
    echo 'exec /var/lib/git/trigger-tekton-task.sh' >> /var/lib/git/.gitolite/hooks/common/post-receive && \
    chmod +x /var/lib/git/.gitolite/hooks/common/post-receive

# Add the Tekton trigger script
RUN chmod +x /var/lib/git/trigger-tekton-task.sh
