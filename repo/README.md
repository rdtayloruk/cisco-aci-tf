# Cisco ACI GitOps - Terraform Configuration

This directory contains the GitOps-driven Terraform codebase for automating configuration across your Cisco ACI fabrics.

## Directory Layout

```text
├── modules/                         # Reusable collection-based thin Terraform modules
│   ├── tenant/                      # Tenant creation
│   ├── vrf/                         # VRF collection
│   ├── bd/                          # Bridge Domain and Subnets collection
│   ├── epg/                         # EPGs, contracts, domains
│   ├── contract/                    # Contracts and subjects collection
│   ├── vlan-pool/                   # VLAN Pools and ranges
│   ├── aaep/                        # AAEP and domain bindings
│   ├── interface-policy-group/      # Access and bundle leaf policy groups
│   └── static-binding/              # Static path bindings
└── scopes/                          # Terraform execution scopes (State boundaries)
    ├── tenants/                     # Logical tenant constructs (e.g. OSS/, OSS-DMZ/)
    ├── access-policies/             # Physical access constructs (e.g. shared/, services/)
    └── fabric-policies/             # Fabric-wide policies (e.g. local-fabric/)
```

## Design Rationale

1. **Reduce Blast Radius**: The execution roots are split into durable config domains (tenant scopes, access-policy scopes, fabric-policy scopes). Each scope owns its own remote state.
2. **Collection-Based Modules**: Each module accepts a map of its resources and loops over them internally using `for_each`. The scope `main.tf` acts as a clean wiring layer passing variables directly through to modules.
3. **Simplicity over Abstraction**: No complex YAML inventory parser or emulation of Cisco NaC. Simple HCL modules with auto-loaded `*.auto.tfvars` files are used.
4. **Escape Hatches**: Provider-native resources or `aci_rest_managed` are allowed directly in the scopes (e.g. physical domains in `access-policies` or fabric policies in `fabric-policies`) as escape hatches until module coverage matures.

## Pipeline Secrets

The CI/CD pipelines require the following secrets configured in Gitea under **Settings → Secrets**:

| Secret | Description |
|---|---|
| `ACI_USERNAME` | APIC admin username |
| `ACI_PASSWORD` | APIC admin password |
| `ACI_URL` | APIC base URL |
| `TF_HTTP_USERNAME` | Gitea username for Terraform state backend |
| `TF_HTTP_PASSWORD` | Gitea password for Terraform state backend |

Only changes under `scopes/**` trigger pipeline execution.

## Operations

### How to Make Changes
- Modify the appropriate scope `*.auto.tfvars` file (e.g., `tenant.auto.tfvars` under `scopes/tenants/OSS/`).
- Commit and push to a feature branch, then open a Pull Request.

### How to Add/Delete a Tenant
1. **Add**: Create a new directory under `scopes/tenants/<NAME>/`, copy the boilerplate `main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`, `versions.tf`, `backend.tf`, and create a `tenant.auto.tfvars` file. Add the new scope and a corresponding state name to the matrix in `.gitea/workflows/terraform-pr.yml` and `terraform-apply.yml`.
2. **Delete**: Run `terraform destroy` in the tenant scope directory (or empty the tfvars and apply), delete the scope folder, and remove it from the workflow files.

### How to Add a New Attribute to a Resource
1. Add the new attribute to the module's `variables.tf` as an `optional()` object field.
2. Update the resource definition in the module's `main.tf` to use the new variable attribute.
3. Add the same `optional()` field to the scope's `variables.tf` type definition.
4. Set the value in the scope's `*.auto.tfvars` file.
**Note**: The scope `main.tf` is never touched because it passes variables as whole maps directly.