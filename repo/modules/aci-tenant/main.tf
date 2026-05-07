resource "aci_tenant" "main" {
  name        = var.tenant_name
  description = var.description
}

resource "aci_vrf" "main" {
  for_each = var.vrfs

  tenant_dn = aci_tenant.main.id
  name      = each.key
}

resource "aci_bridge_domain" "main" {
  for_each = var.bridge_domains

  tenant_dn          = aci_tenant.main.id
  relation_fv_rs_ctx = aci_vrf.main[each.value.vrf_name].id
  name               = each.key
}

resource "aci_subnet" "main" {
  for_each = {
    for pair in flatten([
      for bd_name, bd in var.bridge_domains : [
        for subnet_key, subnet in bd.subnets : {
          key      = "${bd_name}_${subnet_key}"
          bd_name  = bd_name
          ip       = subnet.ip
          scope    = subnet.scope
        }
      ]
    ]) : pair.key => pair
  }

  parent_dn = aci_bridge_domain.main[each.value.bd_name].id
  ip        = each.value.ip
  scope     = each.value.scope
}

resource "aci_application_profile" "main" {
  for_each = var.application_profiles

  tenant_dn = aci_tenant.main.id
  name      = each.key
}

resource "aci_application_epg" "main" {
  for_each = {
    for pair in flatten([
      for ap_name, ap in var.application_profiles : [
        for epg_name, epg in ap.epgs : {
          key     = "${ap_name}_${epg_name}"
          ap_name = ap_name
          name    = epg_name
          bd_name = epg.bd_name
        }
      ]
    ]) : pair.key => pair
  }

  application_profile_dn = aci_application_profile.main[each.value.ap_name].id
  name                   = each.value.name
  relation_fv_rs_bd      = aci_bridge_domain.main[each.value.bd_name].id
}
