# Cisco ACI GitOps - Terraform Configuration

This directory contains the GitOps-driven Terraform codebase for automating configuration across your Cisco ACI fabrics.

## Directory Layout

```text
├── modules/                   # Reusable, standardized building blocks
│   ├── aci-tenant/            # Dynamic, schema-driven Tenant/VRF/BD/EPG creation
│   └── aci-access/            # Core module for VLAN Pools, Physical Domains, AAEPs
└── environments/              # Root modules (State boundaries)
    ├── dev/                   # Development APIC instance
    │   ├── access-policies/   # Interfaces, AAEPs, switch configuration
    │   ├── fabric-policies/   # BGP, DNS, NTP, Pod settings
    │   └── tenants/           # Business-specific logical configurations
    ├── prod-lon/              # London Production APIC instance
    │   ├── access-policies/
    │   ├── fabric-policies/
    │   └── tenants/
    └── prod-fra/              # Frankfurt Production APIC instance
        ├── access-policies/
        ├── fabric-policies/
        └── tenants/
```

## Modular Design Principles

To maximize safety and maintainability:
1. **Reduce Blast Radius**: Every subdirectory inside an environment represents an isolated state boundary with its own Gitea HTTP remote state. A failure or lock in `tenants` will never impact `access-policies` or `fabric-policies`.
2. **Align with APIC Model**: The structure mirrors the APIC GUI screen structure (Access Policies, Fabric, Tenants), making it highly intuitive for ACI engineers to locate configurations.
3. **Write Dry Code**: Avoid duplicating resources. Utilize variables and custom schemas with the [`aci-tenant`](./modules/aci-tenant) module to stamp out logical tenant architectures.