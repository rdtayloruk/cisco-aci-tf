output "vlan_pool_ids" {
  description = "Map of VLAN pool name to DN"
  value       = module.vlan_pools.ids
}

output "physical_domain_ids" {
  description = "Map of physical domain name to DN"
  value       = { for k, v in aci_physical_domain.this : k => v.id }
}

output "aaep_ids" {
  description = "Map of AAEP name to DN"
  value       = module.aaeps.ids
}

output "interface_policy_group_ids" {
  description = "Map of interface policy group name to DN"
  value       = module.interface_policy_groups.ids
}
