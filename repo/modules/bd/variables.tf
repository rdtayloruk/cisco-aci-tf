variable "tenant_dn" {
  description = "DN of the parent tenant"
  type        = string
}

variable "vrf_ids" {
  description = "Map of VRF name to DN, from the vrf module output"
  type        = map(string)
  default     = {}
}

variable "bridge_domains" {
  description = "Map of bridge domains to create. Key is the BD name."
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
