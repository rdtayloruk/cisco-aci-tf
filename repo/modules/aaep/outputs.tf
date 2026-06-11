output "ids" {
  description = "Map of AAEP name to DN"
  value       = { for k, v in aci_attachable_access_entity_profile.this : k => v.id }
}
