variable "aci_username" {
  description = "Username for Cisco ACI APIC"
  type        = string
  default     = "admin"
}

variable "aci_password" {
  description = "Password for Cisco ACI APIC"
  type        = string
  sensitive   = true
  default     = "##########"
}

variable "aci_url" {
  description = "URL for Cisco ACI APIC"
  type        = string
  default     = "https://sandboxapicdc.cisco.com" # Should be updated to the London APIC URL
}

variable "tenant_name" {
  description = "Name of the Tenant"
  type        = string
  default     = "prod_lon_tenant"
}

variable "description" {
  description = "Description of the Tenant"
  type        = string
  default     = "London Prod Tenant managed by Terraform GitOps"
}

variable "vrfs" {
  description = "VRFs to configure"
  type        = set(string)
  default     = ["prod_lon_vrf"]
}

variable "bridge_domains" {
  description = "Bridge domains to configure"
  type = map(object({
    vrf_name = string
    subnets = map(object({
      ip    = string
      scope = list(string)
    }))
  }))
  default = {
    "prod_lon_bd" = {
      vrf_name = "prod_lon_vrf"
      subnets = {
        "sub1" = {
          ip    = "10.20.1.1/24"
          scope = ["public"]
        }
      }
    }
  }
}

variable "application_profiles" {
  description = "Application profiles to configure"
  type = map(object({
    epgs = map(object({
      bd_name = string
    }))
  }))
  default = {
    "prod_lon_ap" = {
      epgs = {
        "prod_lon_epg" = {
          bd_name = "prod_lon_bd"
        }
      }
    }
  }
}
