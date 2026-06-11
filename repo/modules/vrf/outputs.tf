output "ids" {
  description = "Map of VRF name to DN"
  value       = { for k, v in aci_vrf.this : k => v.id }
}
