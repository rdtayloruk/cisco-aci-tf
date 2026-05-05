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
2. **Develop**: Make your Terraform changes under the appropriate folder in the `environments/` directory (e.g., `environments/dev/tenants/`, `environments/prod-lon/access-policies/`, etc.).
3. **Commit & Push**:
   ```bash
   git add .
   git commit -m "Add new ACI configuration"
   git push origin feature/my-new-config
   ```
4. **Create PR**: Open a Pull Request in Gitea from your feature branch to `main`.
5. **Plan**: Gitea Actions will automatically trigger a `terraform plan` for the modified environments and post the output as a comment on the PR.

### Deploying Changes
1. **Review**: Review the plan output in the PR comments.
2. **Merge**: Once approved, merge the PR into the `main` branch.
3. **Apply**: Merging to `main` triggers the **Terraform Apply** action, which provisions the changes to the specific Cisco ACI environments.

## Project Structure
- `docker-compose.yml`: Infrastructure definition (Gitea + Runner).
- `scripts/`: Initialization and helper scripts.
- `repo/`: Source code for the Cisco ACI Terraform project.
  - `.gitea/workflows/`: CI/CD pipeline definitions.
  - `modules/`: Standardized, reusable architectural blocks for ACI.
    - `aci-tenant/`: Deploys Tenant-level structures (Tenant, VRFs, Bridge Domains, Subnets, App Profiles, EPGs) dynamically.
    - `aci-access/`: Manages Access and Physical policies (VLAN pools, Physical Domains, AAEPs).
  - `environments/`: Root composition modules for each APIC instance, maintaining isolated state boundaries:
    - `dev/`: Development APIC instance.
    - `prod-lon/`: London Production APIC instance.
    - `prod-fra/`: Frankfurt Production APIC instance.
    *Each environment contains:*
    - `access-policies/`: Physical/Access configurations (domains, VLANs, switch policies).
    - `fabric-policies/`: Global Fabric policies (DNS, NTP, BGP Route Reflectors).
    - `tenants/`: Dynamic logical customer configuration calling the reusable `aci-tenant` module.

