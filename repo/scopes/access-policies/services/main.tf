module "vlan_pools" {
  source     = "../../../modules/vlan-pool"
  vlan_pools = var.vlan_pools
}

resource "aci_physical_domain" "this" {
  for_each = toset(var.physical_domains)
  name     = each.key
}

module "aaeps" {
  source = "../../../modules/aaep"
  aaeps  = var.aaeps
}

module "interface_policy_groups" {
  source                  = "../../../modules/interface-policy-group"
  interface_policy_groups = var.interface_policy_groups
  aaep_ids                = module.aaeps.ids
}
