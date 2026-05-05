output "vlan_pool_ids" {
  description = "Map of VLAN Pool names to their distinguished names (DNs)."
  value       = { for k, v in aci_vlan_pool.main : k => v.id }
}

output "physical_domain_ids" {
  description = "Map of Physical Domain names to their distinguished names (DNs)."
  value       = { for k, v in aci_physical_domain.main : k => v.id }
}

output "aaep_ids" {
  description = "Map of AAEP names to their distinguished names (DNs)."
  value       = { for k, v in aci_attachable_access_entity_profile.main : k => v.id }
}
