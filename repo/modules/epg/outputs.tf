output "ap_ids" {
  description = "Map of application profile name to DN"
  value       = { for k, v in aci_application_profile.this : k => v.id }
}

output "epg_ids" {
  description = "Map of EPG key (ap/epg) to DN"
  value       = { for k, v in aci_application_epg.this : k => v.id }
}
