Create a new branch with chnages to repo/ for managing a single ACI instance using the native Cisco ACI Terraform provider.

Goals:
- keep reusable modules in the same repo
- use HCL + tfvars only
- no YAML inventory
- I want to start simple so do not try to emulate Cisco NaC, though keep in mind it could be the end goal long term: https://github.com/netascode/terraform-aci-nac-aci
- keep modules thin and close to the native provider
- define clear execution scopes and state boundaries

Top-level structure:
- modules/    reusable thin Terraform modules
- scopes/      Terraform execution scopes

Repo structure:
repo/
  modules/
    tenant/
    vrf/
    bd/
    epg/
    contract/
    vlan-pool/
    aaep/
    interface-policy-group/
    static-binding/

  scopes/
    tenants/
      OSS/
      OSS-DMZ/

    access-policies/
      shared/
      services/

    fabric-policies/
      local-fabric/

scope contents:
Each execution scope must contain:
- main.tf
- variables.tf
- outputs.tf
- providers.tf
- versions.tf
- backend.tf
- one primary *.auto.tfvars file appropriate to that scope:
  - tenant.auto.tfvars
  - access.auto.tfvars
  - fabric.auto.tfvars

State model:
- one remote state per execution scope
- do not create a long-lived state per project, ticket, or MOP
- states are based on durable config domains:
  - tenant scopes
  - access-policy scopes
  - fabric-policy scopes

Module design:
Build thin local modules for:
- tenant
- vrf
- bd
- epg
- contract
- vlan-pool
- aaep
- interface-policy-group
- static-binding

Design rules:
- use local module paths
- keep the repo already instance-scoped; do not repeat site names in subfolder names
- keep logic and data in HCL for Phase 1
- prefer simplicity over abstraction
- allow provider-native resources or aci_rest_managed as an escape hatch until module coverage matures

Functional split:
- scopes/tenants/* = logical tenant constructs
- scopes/access-policies/* = physical access constructs
- scopes/fabric-policies/* = fabric-wide/shared constructs

Intent:
This repo should be a clean, simple, native-provider-based starting point that can be extended later, but should not yet move towards a YAML inventory model or Cisco NaC style abstraction.