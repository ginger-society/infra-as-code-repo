# Welcome to [Your Company Name] 🎉

Welcome aboard! We're excited to have you join the team as a Full Stack Engineer. This document will walk you through your initial setup and provide an overview of our tech stack, tools, and processes to help you hit the ground running. Let's dive in!

## Table of Contents

1. [Getting Access](#getting-access)
2. [Setting Up Your Development Environment](#setting-up-your-development-environment)
3. [Tech Stack Overview](#tech-stack-overview)
4. [Working with Repositories](#working-with-repositories)
5. [Deployment and Environments](#deployment-and-environments)
6. [Common Tools and Practices](#common-tools-and-practices)
7. [Company Culture and Communication](#company-culture-and-communication)
8. [Additional Resources](#additional-resources)

---

### 1. Getting Access

To get started, you'll need access to the following:

- **GitHub:** Our code is hosted here. Please send your GitHub username to your manager for repo access.
- **Docker Hub:** We use Docker Hub for container images. Share your Docker ID for team access.
- **GCP, AWS, and DigitalOcean:** We use multiple cloud providers, so reach out for access to our resources as needed.
- **Slack (or preferred team communication tool):** For company and team communication.
- **Documentation tools (Confluence, Notion, etc.):** Request access if needed.

---

### 2. Setting Up Your Development Environment

#### 2.1 Clone the Repositories

1. **Clone the main repository** (and any additional ones as directed by your manager).
   ```bash
   git clone https://github.com/[YourCompany]/[MainRepo].git
   ```

2. **Install Dependencies:**
   - **npm:** Run `npm install` where applicable for frontend projects.
   - **Docker:** Pull Docker images or build them locally.

#### 2.2 Set Up Docker

We use Docker extensively for development, staging, and production environments.

- Ensure Docker is installed and running.
- **Pull development images:**
  ```bash
  docker-compose up --build
  ```

#### 2.3 Configure Environment Variables

1. **Environment Files:** Copy `.env.example` to `.env` and update any secrets.
2. **Secrets Management:** We use [GCP Secret Manager/AWS Secrets Manager] (depending on your stack) to securely store and access sensitive information.

---

### 3. Tech Stack Overview

#### Backend

- **Languages:** Rust, Python
- **Database:** PostgreSQL for relational data, Redis for caching
- **Message Broker:** RabbitMQ for queueing
- **Cloud Services:** GCP (primary), AWS (for SES, S3), DigitalOcean (for backup or specific services)

#### Frontend

- **Framework:** ReactJS
- **Package Manager:** npm (pnpm or Yarn if preferred by the team)

#### DevOps

- **Containerization:** Docker
- **CI/CD:** GitHub Actions for automated testing and deployment
- **Orchestration:** Kubernetes for managing our containerized applications

---

### 4. Working with Repositories

We follow a **feature-branch workflow**:

1. **Create a branch** for new features or bug fixes:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Push your changes** and open a **Pull Request (PR)** on GitHub.
3. **PR Reviews:** All PRs require at least one review. Make sure your PR includes meaningful commits and messages.

---

### 5. Deployment and Environments

- **Development:** Local environment with Docker and Docker Compose.
- **Staging:** Managed with Kubernetes and deployed to our staging cluster in GCP.
- **Production:** Kubernetes cluster in GCP, with automated deployments via GitHub Actions.

#### Deployment Process

1. Merge changes to the `main` branch for deployment.
2. **CI/CD Pipeline:** GitHub Actions will automatically build, test, and deploy the application to the specified environment.

---

### 6. Common Tools and Practices

#### Docker and Docker Compose

- **Docker Hub:** All public/private images are available at [Your Docker Hub URL].
- Run `docker-compose up` for local development setup.

#### Kubernetes

We use Kubernetes clusters for production and staging environments, with resources managed by Helm charts. You'll need access to `kubectl` to monitor the clusters.

#### Database Management

- **PostgreSQL:** Access databases through [pgAdmin/other preferred tools]. Make sure to follow our migration guidelines when updating schemas.
- **Redis:** Used primarily for caching. Access via CLI or Redis GUI if needed.

#### Message Queues and Email

- **RabbitMQ:** Used for handling async tasks. Use the RabbitMQ dashboard for monitoring.
- **SES:** For email functionality. Credentials are available in your environment configuration.

---

### 7. Company Culture and Communication

- **Daily Standups:** We have quick standups to check in on daily progress and blockers.
- **Slack Channels:** Use specific channels for queries (#frontend, #backend, etc.)
- **Documentation:** Update documentation when you work on new features or processes.

---

### 8. Additional Resources

- **API Documentation:** Refer to [API documentation URL] for REST and GraphQL endpoint details.
- **Code Style Guides:** Refer to our [JavaScript/Rust/Python] guidelines in the repo.
- **Onboarding Checklist:** Complete the onboarding checklist available in [Project Management Tool/Notion].



---- Notes----


kubectl scale statefulset dc01-pg-db-1-postgresql --replicas=1
for installing tekton: 




nginx proxy for the gitloite 
stream {
    server {
        listen 3333;
        proxy_pass 192.168.49.2:31163;
    }

    server {
        listen 5000;
        proxy_pass 192.168.49.2:32638;
        proxy_connect_timeout 10s;
        proxy_timeout 300s;
    }
}
in .ssh/config

Host source.gingersociety.org
    User git
    HostName source.gingersociety.org
    Port 3333
    IdentityFile ~/.ssh/id_ed25519

---- for creating private key inside the secret : 

kubectl create secret generic ssh-private-key --from-file=id_ed25519=runner-private-key



kubectl delete pod --field-selector=status.phase==Failed
kubectl delete pod --field-selector=status.phase==Succeeded


kubectl create secret generic pg-credentials \
  --from-literal=password='your_postgres_password'

kubectl create secret generic aws-creds \
  --from-literal=access_key='your_aws_access_key' \
  --from-literal=secret_key='your_aws_secret_key'


kubectl create secret generic pipeline-secrets-secret   --from-env-file=secrets.env   -n tasks-rackmint-provisioner-service