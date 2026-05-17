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
  default     = "https://sandboxapicdc.cisco.com"
}

variable "tenant_name" {
  description = "Name of the Tenant"
  type        = string
}

variable "description" {
  description = "Description of the Tenant"
  type        = string
  default     = ""
}

variable "vrfs" {
  description = "VRFs to configure"
  type        = set(string)
  default     = []
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
  default = {}
}

variable "application_profiles" {
  description = "Application profiles to configure"
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
