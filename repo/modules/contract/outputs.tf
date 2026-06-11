output "ids" {
  description = "Map of contract name to DN"
  value       = { for k, v in aci_contract.this : k => v.id }
}
