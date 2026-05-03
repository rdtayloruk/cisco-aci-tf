# Cisco ACI GitOps Automation Platform

This project provides a complete, self-hosted GitOps environment for managing Cisco ACI infrastructure. It leverages Gitea for source control and CI/CD (Gitea Actions), and Terraform for Infrastructure as Code.

## Prerequisites
- Docker and Docker Compose
- Basic knowledge of Cisco ACI and Terraform

## Getting Started

### 1. Start the Environment
Run the following command to start Gitea and the Actions Runner:
```bash
docker-compose up -d
```

### 2. Initialize the Platform
Execute the bootstrap script to create users, organizations, repositories, and register the Actions Runner:
```bash
./scripts/bootstrap.sh
```

### 3. Access Gitea
- **URL**: http://localhost:3000
- **Admin User**: `cisco-aci-admin` / `Admin123!`
- **Standard User**: `cisco-aci-user` / `User123!`

## GitOps Workflow

### Initial Setup
1. Clone the repository from Gitea: `http://localhost:3000/cisco-aci/cisco-aci-tf.git`
2. Push the contents of the `repo/` directory to the Gitea repository.

### Raising a Pull Request
1. **Branching**: Create a new branch for your changes:
   ```bash
   git checkout -b feature/my-new-config
   ```
2. **Develop**: Make your Terraform changes in the `staging/` directory.
3. **Commit & Push**:
   ```bash
   git add .
   git commit -m "Add new ACI configuration"
   git push origin feature/my-new-config
   ```
4. **Create PR**: Open a Pull Request in Gitea from your feature branch to `main`.
5. **Plan**: Gitea Actions will automatically trigger a `terraform plan` and post the output as a comment on the PR.

### Deploying Changes
1. **Review**: Review the plan output in the PR comments.
2. **Merge**: Once approved, merge the PR into the `main` branch.
3. **Apply**: Merging to `main` triggers the **Terraform Apply** action, which provisions the changes to the Cisco ACI environment.

## Project Structure
- `docker-compose.yml`: Infrastructure definition (Gitea + Runner).
- `scripts/`: Initialization and helper scripts.
- `repo/`: Source code for the Cisco ACI Terraform project.
  - `.gitea/workflows/`: CI/CD pipeline definitions.
  - `staging/`: Terraform configuration for the staging environment.
