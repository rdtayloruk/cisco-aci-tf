variable "aci_username" {
  description = "Username for Cisco ACI APIC"
  type        = string
  default     = "admin"
}

variable "aci_password" {
  description = "Password for Cisco ACI APIC"
  type        = string
  sensitive   = true
}

variable "aci_url" {
  description = "URL for Cisco ACI APIC"
  type        = string
}

variable "tenant_name" {
  description = "Name of the ACI tenant"
  type        = string
}

variable "description" {
  description = "Description for the tenant"
  type        = string
  default     = ""
}

variable "vrfs" {
  description = "Map of VRFs to create"
  type = map(object({
    description = optional(string, "")
  }))
  default = {}
}

variable "bridge_domains" {
  description = "Map of bridge domains to create"
  type = map(object({
    vrf_name    = string
    description = optional(string, "")
    subnets = optional(map(object({
      ip    = string
      scope = list(string)
    })), {})
  }))
  default = {}
}

variable "contracts" {
  description = "Map of contracts to create"
  type = map(object({
    description = optional(string, "")
    scope       = optional(string, "tenant")
    subjects    = optional(list(string), ["default"])
  }))
  default = {}
}

variable "application_profiles" {
  description = "Map of application profiles with nested EPGs"
  type = map(object({
    description = optional(string, "")
    epgs = map(object({
      bd_name            = string
      description        = optional(string, "")
      consumed_contracts = optional(list(string), [])
      provided_contracts = optional(list(string), [])
      domain_dns         = optional(list(string), [])
    }))
  }))
  default = {}
}
