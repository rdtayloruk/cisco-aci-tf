resource "aci_bridge_domain" "this" {
  for_each           = var.bridge_domains
  tenant_dn          = var.tenant_dn
  name               = each.key
  description        = each.value.description
  relation_fv_rs_ctx = var.vrf_ids[each.value.vrf_name]
}

locals {
  subnets = flatten([
    for bd_name, bd in var.bridge_domains : [
      for sk, sv in bd.subnets : {
        key     = "${bd_name}/${sk}"
        bd_name = bd_name
        ip      = sv.ip
        scope   = sv.scope
      }
    ]
  ])
}

resource "aci_subnet" "this" {
  for_each  = { for s in local.subnets : s.key => s }
  parent_dn = aci_bridge_domain.this[each.value.bd_name].id
  ip        = each.value.ip
  scope     = each.value.scope
}
