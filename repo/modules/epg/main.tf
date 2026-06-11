resource "aci_application_profile" "this" {
  for_each    = var.application_profiles
  tenant_dn   = var.tenant_dn
  name        = each.key
  description = each.value.description
}

locals {
  epgs = flatten([
    for ap, cfg in var.application_profiles : [
      for epg, ecfg in cfg.epgs : {
        key     = "${ap}/${epg}"
        ap      = ap
        name    = epg
        bd_name = ecfg.bd_name
        desc    = ecfg.description
      }
    ]
  ])

  consumed = flatten([
    for ap, cfg in var.application_profiles : [
      for epg, ecfg in cfg.epgs : [
        for c in ecfg.consumed_contracts : {
          key      = "${ap}/${epg}/consumer/${c}"
          epg_key  = "${ap}/${epg}"
          contract = c
          type     = "consumer"
        }
      ]
    ]
  ])

  provided = flatten([
    for ap, cfg in var.application_profiles : [
      for epg, ecfg in cfg.epgs : [
        for c in ecfg.provided_contracts : {
          key      = "${ap}/${epg}/provider/${c}"
          epg_key  = "${ap}/${epg}"
          contract = c
          type     = "provider"
        }
      ]
    ]
  ])

  domains = flatten([
    for ap, cfg in var.application_profiles : [
      for epg, ecfg in cfg.epgs : [
        for d in ecfg.domain_dns : {
          key     = "${ap}/${epg}/${d}"
          epg_key = "${ap}/${epg}"
          tdn     = d
        }
      ]
    ]
  ])
}

resource "aci_application_epg" "this" {
  for_each               = { for e in local.epgs : e.key => e }
  application_profile_dn = aci_application_profile.this[each.value.ap].id
  name                   = each.value.name
  relation_fv_rs_bd      = var.bd_ids[each.value.bd_name]
  description            = each.value.desc
}

resource "aci_epg_to_contract" "this" {
  for_each           = { for c in concat(local.consumed, local.provided) : c.key => c }
  application_epg_dn = aci_application_epg.this[each.value.epg_key].id
  contract_dn        = var.contract_ids[each.value.contract]
  contract_type      = each.value.type
}

resource "aci_epg_to_domain" "this" {
  for_each           = { for d in local.domains : d.key => d }
  application_epg_dn = aci_application_epg.this[each.value.epg_key].id
  tdn                = each.value.tdn
}
