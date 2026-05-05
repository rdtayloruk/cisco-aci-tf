module "access_policies" {
  source = "../../../modules/aci-access"

  vlan_pools = var.vlan_pools
}
