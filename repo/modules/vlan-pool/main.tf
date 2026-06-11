resource "aci_vlan_pool" "this" {
  for_each   = var.vlan_pools
  name       = each.key
  alloc_mode = each.value.alloc_mode
}

locals {
  ranges = flatten([
    for pool, cfg in var.vlan_pools : [
      for r in cfg.ranges : {
        key        = "${pool}/${r.start}-${r.end}"
        pool       = pool
        start      = r.start
        end        = r.end
        alloc_mode = coalesce(r.alloc_mode, cfg.alloc_mode)
        role       = coalesce(r.role, "external")
      }
    ]
  ])
}

resource "aci_ranges" "this" {
  for_each     = { for r in local.ranges : r.key => r }
  vlan_pool_dn = aci_vlan_pool.this[each.value.pool].id
  from         = "vlan-${each.value.start}"
  to           = "vlan-${each.value.end}"
  alloc_mode   = each.value.alloc_mode
  role         = each.value.role
}
