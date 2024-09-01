# First stage: Build the Rust application
FROM rust:1-slim-bullseye
RUN apt-get update && apt-get install -y pkg-config libssl-dev libpq-dev curl

# Install Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_current.x | bash -
RUN apt install -y nodejs

# Install Java
RUN apt install -y default-jdk

# Install OpenAPI Generator CLI globally
RUN npm install @openapitools/openapi-generator-cli -g

RUN curl "https://ginger-connector-binaries.s3.ap-south-1.amazonaws.com/0.7.0-nightly.0/x86_64-unknown-linux-gnu/ginger-connector" -o "/usr/local/bin/ginger-connector"

RUN curl "https://ginger-auth-binaries.s3.ap-south-1.amazonaws.com/0.1.0/x86_64-unknown-linux-gnu/ginger-auth" -o "/usr/local/bin/ginger-auth"


RUN chmod u+x /usr/local/bin/ginger-connector
RUN chmod u+x /usr/local/bin/ginger-auth
