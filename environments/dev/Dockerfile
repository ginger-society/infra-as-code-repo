FROM debian:bullseye-slim

WORKDIR /workspace

# Update package list
RUN apt update

# Install necessary packages
RUN apt install git zsh curl nano make gcc wget build-essential procps unzip -y

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" -y

# Set zsh as the default shell
RUN echo "zsh" >> ~/.bashrc 

# Install Node.js
RUN sh -c "$(curl -fsSL https://deb.nodesource.com/setup_current.x)" -y
RUN apt install nodejs -y

RUN bash -c "$(curl -fsSL https://raw.githubusercontent.com/ginger-society/infra-as-code-repo/main/rust-helpers/install-all-clis.sh)"

# Install yarn globally
RUN npm install -g yarn

# Install Java
RUN apt install default-jdk -y

# Install OpenAPI Generator CLI globally
RUN npm install @openapitools/openapi-generator-cli -g

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install

# Verify OpenAPI Generator installation
RUN openapi-generator-cli version



RUN curl -fsSL https://code-server.dev/install.sh | sh


RUN useradd -m -s /bin/zsh coder && \
    mkdir -p /home/coder/.config/code-server && \
    echo "${PASSWORD}" > /home/coder/.config/code-server/password && \
    chown -R coder:coder /home/coder/.config

# Switch to non-root user
USER coder

# Expose the VS Code UI port
EXPOSE 8080

# Start code-server
CMD ["code-server", "--bind-addr", "0.0.0.0:8080", "--auth", "password", "--user-data-dir", "/home/coder", "--extensions-dir", "/home/coder/.vscode/extensions"]