variable "tenant_dn" {
  description = "DN of the parent tenant"
  type        = string
}

variable "vrfs" {
  description = "Map of VRFs to create. Key is the VRF name."
  type = map(object({
    description = optional(string, "")
  }))
  default = {}
}
