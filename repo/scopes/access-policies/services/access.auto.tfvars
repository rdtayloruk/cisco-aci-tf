vlan_pools = {
  "services-static-pool" = {
    alloc_mode = "static"
    ranges = [
      {
        start = 200
        end   = 299
      }
    ]
  }
}

physical_domains = ["services-phys-dom"]

aaeps = {
  "services-aaep" = {
    domain_dns = ["uni/phys-services-phys-dom"]
  }
}

interface_policy_groups = {
  "services-access-pg" = {
    type      = "access"
    aaep_name = "services-aaep"
  }
}
