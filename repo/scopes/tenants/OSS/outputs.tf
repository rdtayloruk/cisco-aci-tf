output "tenant_id" {
  description = "DN of the tenant"
  value       = module.tenant.id
}

output "vrf_ids" {
  description = "Map of VRF name to DN"
  value       = module.vrfs.ids
}

output "bd_ids" {
  description = "Map of bridge domain name to DN"
  value       = module.bridge_domains.ids
}

output "contract_ids" {
  description = "Map of contract name to DN"
  value       = module.contracts.ids
}

output "epg_ids" {
  description = "Map of EPG key to DN"
  value       = module.epgs.epg_ids
}
