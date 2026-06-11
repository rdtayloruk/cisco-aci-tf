resource "aci_attachable_access_entity_profile" "this" {
  for_each    = var.aaeps
  name        = each.key
  description = each.value.description
}

locals {
  aaep_domains = flatten([
    for name, cfg in var.aaeps : [
      for d in cfg.domain_dns : {
        key       = "${name}/${d}"
        aaep_name = name
        domain_dn = d
      }
    ]
  ])
}

resource "aci_aaep_to_domain" "this" {
  for_each                            = { for d in local.aaep_domains : d.key => d }
  attachable_access_entity_profile_dn = aci_attachable_access_entity_profile.this[each.value.aaep_name].id
  domain_dn                           = each.value.domain_dn
}
