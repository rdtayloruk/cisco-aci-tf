output "ids" {
  description = "Map of interface policy group name to DN"
  value = merge(
    { for k, v in aci_leaf_access_port_policy_group.this : k => v.id },
    { for k, v in aci_leaf_access_bundle_policy_group.this : k => v.id },
  )
}
