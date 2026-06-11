module "tenant" {
  source      = "../../../modules/tenant"
  name        = var.tenant_name
  description = var.description
}

module "vrfs" {
  source    = "../../../modules/vrf"
  tenant_dn = module.tenant.id
  vrfs      = var.vrfs
}

module "bridge_domains" {
  source         = "../../../modules/bd"
  tenant_dn      = module.tenant.id
  bridge_domains = var.bridge_domains
  vrf_ids        = module.vrfs.ids
}

module "contracts" {
  source    = "../../../modules/contract"
  tenant_dn = module.tenant.id
  contracts = var.contracts
}

module "epgs" {
  source               = "../../../modules/epg"
  tenant_dn            = module.tenant.id
  application_profiles = var.application_profiles
  bd_ids               = module.bridge_domains.ids
  contract_ids         = module.contracts.ids
}
