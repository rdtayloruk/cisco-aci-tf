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

variable "vlan_pools" {
  description = "Map of VLAN pools to create"
  type = map(object({
    alloc_mode = string
    ranges = optional(list(object({
      start      = number
      end        = number
      alloc_mode = optional(string)
      role       = optional(string)
    })), [])
  }))
  default = {}
}

variable "physical_domains" {
  description = "List of physical domain names to create"
  type        = list(string)
  default     = []
}

variable "aaeps" {
  description = "Map of AAEPs to create"
  type = map(object({
    description = optional(string, "")
    domain_dns  = optional(list(string), [])
  }))
  default = {}
}

variable "interface_policy_groups" {
  description = "Map of interface policy groups to create"
  type = map(object({
    type        = string
    description = optional(string, "")
    aaep_name   = optional(string)
  }))
  default = {}
}
