# This module manages Cisco ACI Access Policies (VLAN Pools, Domains, Attachable Access Entity Profiles, etc.)
# Customize these resources according to your physical fabric requirements.

resource "aci_vlan_pool" "main" {
  for_each = var.vlan_pools

  name       = each.key
  alloc_mode = each.value.alloc_mode
}

resource "aci_physical_domain" "main" {
  for_each = var.physical_domains

  name = each.key
  # Optionally link to VLAN pool if needed:
  # relation_infra_rs_vlan_ns = aci_vlan_pool.main[each.value.vlan_pool_name].id
}

resource "aci_attachable_access_entity_profile" "main" {
  for_each = var.aaeps

  name = each.key
}
