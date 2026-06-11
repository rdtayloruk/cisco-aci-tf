vlan_pools = {
  "shared-static-pool" = {
    alloc_mode = "static"
    ranges = [
      {
        start = 100
        end   = 199
      }
    ]
  }
}

physical_domains = ["shared-phys-dom"]

aaeps = {
  "shared-aaep" = {
    domain_dns = ["uni/phys-shared-phys-dom"]
  }
}

interface_policy_groups = {
  "shared-access-pg" = {
    type      = "access"
    aaep_name = "shared-aaep"
  }
}
