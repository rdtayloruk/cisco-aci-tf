resource "aci_vrf" "this" {
  for_each    = var.vrfs
  tenant_dn   = var.tenant_dn
  name        = each.key
  description = each.value.description
}
