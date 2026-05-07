output "tenant_id" {
  description = "The distinguished name (DN) of the created Tenant."
  value       = aci_tenant.main.id
}

output "vrf_ids" {
  description = "Map of VRF names to their distinguished names (DNs)."
  value       = { for k, v in aci_vrf.main : k => v.id }
}

output "bridge_domain_ids" {
  description = "Map of Bridge Domain names to their distinguished names (DNs)."
  value       = { for k, v in aci_bridge_domain.main : k => v.id }
}

output "application_profile_ids" {
  description = "Map of Application Profile names to their distinguished names (DNs)."
  value       = { for k, v in aci_application_profile.main : k => v.id }
}

output "epg_ids" {
  description = "Map of EPG names to their distinguished names (DNs)."
  value       = { for k, v in aci_application_epg.main : k => v.id }
}
