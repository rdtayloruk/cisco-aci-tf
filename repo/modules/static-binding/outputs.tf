output "ids" {
  description = "Map of static binding key to DN"
  value       = { for k, v in aci_epg_to_static_path.this : k => v.id }
}
