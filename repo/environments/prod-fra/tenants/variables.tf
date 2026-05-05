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
  default     = "https://sandboxapicdc.cisco.com" # Should be updated to the Frankfurt APIC URL
}

variable "tenant_name" {
  description = "Name of the Tenant"
  type        = string
  default     = "prod_fra_tenant"
}

variable "description" {
  description = "Description of the Tenant"
  type        = string
  default     = "Frankfurt Prod Tenant managed by Terraform GitOps"
}

variable "vrfs" {
  description = "VRFs to configure"
  type        = set(string)
  default     = ["prod_fra_vrf"]
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
    "prod_fra_bd" = {
      vrf_name = "prod_fra_vrf"
      subnets = {
        "sub1" = {
          ip    = "10.30.1.1/24"
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
    "prod_fra_ap" = {
      epgs = {
        "prod_fra_epg" = {
          bd_name = "prod_fra_bd"
        }
      }
    }
  }
}
