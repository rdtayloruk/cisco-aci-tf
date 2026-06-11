output "ids" {
  description = "Map of bridge domain name to DN"
  value       = { for k, v in aci_bridge_domain.this : k => v.id }
}
