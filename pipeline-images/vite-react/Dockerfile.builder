FROM debian:bullseye-slim

# Install bash and basic utilities
RUN apt update && apt install -y bash curl unzip

# Use bash as the default shell
SHELL ["/bin/bash", "-c"]

WORKDIR /app

# Install necessary packages
RUN apt update && apt install -y curl nano make gcc wget build-essential procps

# Install Node.js (version 20.11.0)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt install -y nodejs=20.11.0-1nodesource1

# Install pnpm globally
RUN npm install -g pnpm

# Verify installation
RUN pnpm -v && node -v

# Install necessary CLIs using the provided script
RUN bash -c "$(curl -fsSL https://raw.githubusercontent.com/ginger-society/infra-as-code-repo/main/rust-helpers/install-all-clis.sh)"

# Install Java
RUN apt install -y default-jdk

# Install OpenAPI Generator CLI globally
RUN pnpm add -g @openapitools/openapi-generator-cli

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install

# Verify OpenAPI Generator CLI version
RUN openapi-generator-cli version
