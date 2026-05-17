FROM alpine:latest

RUN apk add --no-cache \
    openssh-client \
    git \
    bash

RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh && \
    printf 'Host source.gingersociety.org\n\
    User git\n\
    HostName source.gingersociety.org\n\
    Port 3333\n\
    IdentityFile ~/.ssh/id_ed25519\n\
    StrictHostKeyChecking no\n\
    UserKnownHostsFile=/dev/null\n' > /root/.ssh/config && \
    chmod 600 /root/.ssh/config


COPY mount-git-credentials.sh /usr/local/bin/mount-git-credentials.sh
RUN chmod +x /usr/local/bin/mount-git-credentials.sh
    