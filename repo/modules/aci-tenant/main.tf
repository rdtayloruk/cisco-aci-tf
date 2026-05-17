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

resource "aci_contract" "main" {
  for_each  = var.contracts
  tenant_dn = aci_tenant.main.id
  name      = each.key
}

locals {
  epg_contract_bindings = flatten([
    for epg_name, bind in var.epg_bindings : [
      for c in bind.contracts : {
        key           = "${bind.app_profile}_${epg_name}_${c.name}_${c.type}"
        ap_name       = bind.app_profile
        epg_name      = epg_name
        contract_name = c.name
        contract_type = c.type
      }
    ]
  ])

  epg_domain_bindings = flatten([
    for epg_name, bind in var.epg_bindings : [
      for d in bind.domain_binds : {
        key         = "${bind.app_profile}_${epg_name}_${d.name}_${d.type}"
        ap_name     = bind.app_profile
        epg_name    = epg_name
        domain_name = d.name
        domain_type = d.type
      }
    ]
  ])
}

resource "aci_epg_to_contract" "main" {
  for_each = { for b in local.epg_contract_bindings : b.key => b }

  application_epg_dn = aci_application_epg.main["${each.value.ap_name}_${each.value.epg_name}"].id
  contract_dn        = aci_contract.main[each.value.contract_name].id
  contract_type      = each.value.contract_type
}

resource "aci_epg_to_domain" "main" {
  for_each = { for b in local.epg_domain_bindings : b.key => b }

  application_epg_dn = aci_application_epg.main["${each.value.ap_name}_${each.value.epg_name}"].id
  tdn                = each.value.domain_type == "phys" ? "uni/phys-${each.value.domain_name}" : (each.value.domain_type == "vmm" ? "uni/vmmp-VMware/dom-${each.value.domain_name}" : "uni/l2dom-${each.value.domain_name}")
}
