variable "tenant_name" {
  description = "Name of the ACI Tenant"
  type        = string
}

variable "description" {
  description = "Description for the Tenant"
  type        = string
  default     = "Managed by Terraform GitOps"
}

variable "vrfs" {
  description = "Set of VRF names to create within the Tenant"
  type        = set(string)
  default     = []
}

variable "bridge_domains" {
  description = "Map of Bridge Domains to create. Key is BD name, value contains configuration."
  type = map(object({
    vrf_name = string
    subnets = map(object({
      ip    = string
      scope = list(string)
    }))
  }))
  default = {}
}

variable "application_profiles" {
  description = "Map of Application Profiles to create. Key is AP name, value contains EPG configuration."
  type = map(object({
    epgs = map(object({
      bd_name = string
    }))
  }))
  default = {}
}

variable "contracts" {
  description = "Set of contract names to create within the Tenant"
  type        = set(string)
  default     = []
}

variable "epg_bindings" {
  description = "Map of EPG bindings (contracts and domains). Key is EPG name."
  type = map(object({
    app_profile = string
    contracts = list(object({
      name = string
      type = string
    }))
    domain_binds = list(object({
      name = string
      type = string
    }))
  }))
  default = {}
}

