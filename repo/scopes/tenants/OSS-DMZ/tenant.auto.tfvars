tenant_name = "OSS-DMZ"
description = "OSS DMZ Tenant managed by Terraform"

vrfs = {
  "OSS-DMZ-VRF" = {}
}

bridge_domains = {
  "OSS-DMZ-BD1" = {
    vrf_name = "OSS-DMZ-VRF"
    subnets = {
      "gateway" = {
        ip    = "10.200.1.1/24"
        scope = ["public"]
      }
    }
  }
}

contracts = {}

application_profiles = {
  "OSS-DMZ-AP" = {
    epgs = {
      "OSS-DMZ-EPG-WEB" = {
        bd_name    = "OSS-DMZ-BD1"
        domain_dns = ["uni/phys-shared-phys-dom"]
      }
    }
  }
}
