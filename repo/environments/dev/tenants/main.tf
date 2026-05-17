module "tenant" {
  source = "../../../modules/aci-tenant"

  tenant_name          = var.tenant_name
  description          = var.description
  vrfs                 = var.vrfs
  bridge_domains       = var.bridge_domains
  application_profiles = var.application_profiles
  contracts            = var.contracts
  epg_bindings         = var.epg_bindings
}
