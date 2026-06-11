locals {
  access = { for k, v in var.interface_policy_groups : k => v if v.type == "access" }
  bundle = { for k, v in var.interface_policy_groups : k => v if v.type == "pc" || v.type == "vpc" }
}

resource "aci_leaf_access_port_policy_group" "this" {
  for_each                    = local.access
  name                        = each.key
  description                 = each.value.description
  relation_infra_rs_att_ent_p = each.value.aaep_name != null ? var.aaep_ids[each.value.aaep_name] : null
}

resource "aci_leaf_access_bundle_policy_group" "this" {
  for_each                    = local.bundle
  name                        = each.key
  description                 = each.value.description
  lag_t                       = each.value.type == "vpc" ? "node" : "link"
  relation_infra_rs_att_ent_p = each.value.aaep_name != null ? var.aaep_ids[each.value.aaep_name] : null
}
