resource "aci_epg_to_static_path" "this" {
  for_each           = var.static_bindings
  application_epg_dn = each.value.epg_dn
  tdn                = each.value.path_dn
  encap              = "vlan-${each.value.vlan}"
  mode               = each.value.mode
  instr_imedcy       = each.value.deployment_immediacy
}
