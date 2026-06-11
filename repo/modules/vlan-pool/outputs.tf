output "ids" {
  description = "Map of VLAN pool name to DN"
  value       = { for k, v in aci_vlan_pool.this : k => v.id }
}
