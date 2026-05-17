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

### 3. Import Existing ACI State (Optional)
If you have existing resources already configured on the APIC, you must import them into the Terraform state before running any `terraform plan` or `apply`. This prevents Terraform from attempting to recreate or destroy resources that already exist in the real world.

**Important:** The `import-state.sh` script does **not** automatically generate Terraform code (`.tf` or `.tfvars` files) for you. It only updates the backend state file.

#### How to use the Import Script
1. **Define Your Infrastructure in Code First:** Before running the script, you must manually define the existing ACI resources in your `.auto.tfvars` file (e.g., `environments/dev/tenants/dev.auto.tfvars`).
    ```hcl
    # Example dev.auto.tfvars defining an existing VRF and Bridge Domain
    vrfs = ["dev_vrf"]
    
    bridge_domains = {
      "dev_bd" = {
        vrf_name = "dev_vrf"
        subnets = {
          "sub1" = {
            ip    = "10.10.1.1/24"
            scope = ["public"]
          }
        }
      }
    }
    ```
2. **Run the Script:** 
    ```bash
    ACI_PASSWORD=<apic-password> ./scripts/import-state.sh
    ```
3. **What the Script Does:** It acts as an automated import engine. It dynamically reads your `.auto.tfvars` variables, connects to the Cisco APIC to verify that those objects (VRFs, BDs, Subnets) actually exist, and automatically generates and runs the highly-specific `terraform import` commands for you. It is safe to run multiple times — resources already in state are skipped.

**Key environment variables:**

| Variable | Default | Description |
|---|---|---|
| `ACI_PASSWORD` | *(required)* | APIC admin password |
| `ACI_USERNAME` | `admin` | APIC admin username |
| `ACI_URL` | Cisco DevNet sandbox | Default APIC URL for all environments |
| `ACI_URL_DEV` | `ACI_URL` | Override APIC URL for the `dev` environment |
| `GITEA_URL` | `http://localhost:3000` | Gitea base URL |
| `GITEA_PASSWORD` | `Admin123!` | Gitea admin password for state backend auth |

> **Note:** `bootstrap.sh` will call `import-state.sh` automatically if `ACI_PASSWORD` is set when it runs.

### 4. Access Gitea
- **URL**: http://localhost:3000
- **Admin User**: `cisco-aci-admin` / `Admin123!`
- **Standard User**: `cisco-aci-user` / `User123!`

## GitOps Workflow

### Sandbox vs. Active GitOps Repositories

To maintain a clean workflow, keep your local project environments separated:
* 📁 **Sandbox Repository (`cisco-aci-tf`)**: This is your current management directory containing Gitea, Runners, Docker-compose files, bootstrap scripts, and a local template of the infrastructure under `repo/`.
* 📁 **Active GitOps Repository (`cisco-aci-tf-gitops`)**: This is the dedicated folder where you perform active Terraform developments, create branches, and push changes to trigger CI/CD pipelines.

> [!IMPORTANT]
> **Avoid Nested Git Repositories!**
> Do not permanently run `git init` or active development inside your sandbox's `repo/` subdirectory. Doing so creates a nested `.git` folder, which causes Git tracking mismatches and warnings. Instead, follow the initial setup below to push the template, clean it up, and clone it to a separate directory.

---

### Initial Setup (Seeding Gitea)

Run these commands on your host terminal to initialize Gitea's remote repository with the contents of the `repo/` template folder and safely remove any temporary tracking:

```bash
# 1. Enter the local template directory
cd repo

# 2. Temporarily initialize Git
git init
git checkout -b main
git config user.name "Cisco ACI Admin"
git config user.email "cisco-aci-admin@example.com"

# 3. Commit the template contents
git add .
git commit -m "Initial commit of Cisco ACI Terraform infrastructure configurations"

# 4. Push to Gitea (URL-encoding the '!' in Admin123! as '%21' to prevent shell errors)
git remote add origin http://cisco-aci-admin:Admin123%21@localhost:3000/cisco-aci/cisco-aci-tf.git
git push -u origin main --force

# 5. Crucial: Remove the temporary .git directory to prevent nested repository tracking
rm -rf .git
```

---

### Working with the Active Repository

Once Gitea is seeded, clone the repository to a completely separate workspace directory on your machine to perform your daily GitOps tasks:

```bash
# 1. Navigate out of the sandbox directory (e.g. to your home folder)
cd ~/

# 2. Clone Gitea's repository to a dedicated folder
git clone http://localhost:3000/cisco-aci/cisco-aci-tf.git cisco-aci-tf-gitops

# 3. Change into the active repository directory
cd cisco-aci-tf-gitops
```

---

### Raising a Pull Request (GitOps flow)

Always perform your feature developments inside the separately cloned `cisco-aci-tf-gitops` folder:

1. **Branching**: Create a new branch for your changes:
   ```bash
   git checkout -b feature/my-new-config
   ```
2. **Develop**: Make your Terraform changes under the appropriate folder in the `environments/` directory (e.g., `environments/dev/tenants/`, etc.).
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
  - `bootstrap.sh`: Sets up Gitea users, org, repo, and Actions Runner.
  - `import-state.sh`: Imports pre-existing ACI resources into Terraform state.
- `repo/`: Source code for the Cisco ACI Terraform project.
  - `.gitea/workflows/`: CI/CD pipeline definitions.
  - `modules/`: Standardized, reusable architectural blocks for ACI.
    - `aci-tenant/`: Deploys Tenant-level structures (Tenant, VRFs, Bridge Domains, Subnets, App Profiles, EPGs) dynamically.
    - `aci-access/`: Manages Access and Physical policies (VLAN pools, Physical Domains, AAEPs).
  - `environments/`: Root composition modules for each APIC instance, maintaining isolated state boundaries:
    - `dev/`: Development APIC instance.
    *Each environment contains:*
    - `access-policies/`: Physical/Access configurations (domains, VLANs, switch policies).
    - `fabric-policies/`: Global Fabric policies (DNS, NTP, BGP Route Reflectors).
    - `tenants/`: Dynamic logical customer configuration calling the reusable `aci-tenant` module.

