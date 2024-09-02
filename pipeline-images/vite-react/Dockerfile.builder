FROM debian:bullseye-slim

# Install bash
RUN apt update && apt install -y bash curl unzip

# Use bash as the default shell
SHELL ["/bin/bash", "-c"]

WORKDIR /app

# Install necessary packages
RUN apt update && apt install -y curl nano make gcc wget build-essential procps

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_current.x | bash -
RUN apt install -y nodejs

# Install yarn globally
RUN npm install -g yarn

RUN curl "https://ginger-connector-binaries.s3.ap-south-1.amazonaws.com/0.7.0-nightly.0/x86_64-unknown-linux-gnu/ginger-connector" -o "ginger-connector"
RUN chmod u+x ginger-connector

RUN curl "https://ginger-auth-binaries.s3.ap-south-1.amazonaws.com/0.1.0/x86_64-unknown-linux-gnu/ginger-auth" -o "ginger-auth"
RUN chmod u+x ginger-auth

# Install Java
RUN apt install -y default-jdk

# Install OpenAPI Generator CLI globally
RUN npm install @openapitools/openapi-generator-cli -g

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install

# Verify OpenAPI Generator installation
RUN openapi-generator-cli version