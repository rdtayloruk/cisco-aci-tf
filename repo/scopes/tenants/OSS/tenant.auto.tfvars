tenant_name = "OSS"
description = "OSS Tenant managed by Terraform"

vrfs = {
  "OSS-VRF" = {}
}

bridge_domains = {
  "OSS-BD1" = {
    vrf_name = "OSS-VRF"
    subnets = {
      "gateway" = {
        ip    = "10.100.1.1/24"
        scope = ["public"]
      }
    }
  }
}

contracts = {
  "OSS-WEB-TO-DB" = {}
}

application_profiles = {
  "OSS-AP" = {
    epgs = {
      "OSS-EPG-WEB" = {
        bd_name            = "OSS-BD1"
        consumed_contracts = ["OSS-WEB-TO-DB"]
        provided_contracts = []
        domain_dns         = ["uni/phys-shared-phys-dom"]
      }
    }
  }
}
