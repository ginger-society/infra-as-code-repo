FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install packages that a typical AWS/GCP Ubuntu instance would have
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    sudo \
    systemd \
    systemd-sysv \
    ca-certificates \
    gnupg \
    lsb-release \
    net-tools \
    iproute2 \
    iputils-ping \
    openssh-server \
    unzip \
    git \
    vim \
    htop \
    ufw \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# systemd needs this to run properly in Docker
RUN cd /lib/systemd/system/sysinit.target.wants/ && \
    ls | grep -v systemd-tmpfiles-setup | xargs rm -f && \
    rm -f /lib/systemd/system/multi-user.target.wants/* && \
    rm -f /etc/systemd/system/*.wants/* && \
    rm -f /lib/systemd/system/local-fs.target.wants/* && \
    rm -f /lib/systemd/system/sockets.target.wants/*udev* && \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl* && \
    rm -f /lib/systemd/system/basic.target.wants/* && \
    rm -f /lib/systemd/system/anaconda.target.wants/*

RUN wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb && \
    dpkg -i libssl1.1_1.1.1f-1ubuntu2_amd64.deb && \
    rm libssl1.1_1.1.1f-1ubuntu2_amd64.deb

# Install ginger-auth
RUN bash -c "$(curl -fsSL https://raw.githubusercontent.com/ginger-society/infra-as-code-repo/main/rust-helpers/installer.sh)" -- ginger-society/ginger-auth:latest


# Create a non-root user with sudo (mimics ubuntu user on AWS/GCP)
RUN useradd -m -s /bin/bash ubuntu && \
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
    
VOLUME ["/sys/fs/cgroup"]

EXPOSE 22 80 443

CMD ["/lib/systemd/systemd"]