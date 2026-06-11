variable "tenant_dn" {
  description = "DN of the parent tenant"
  type        = string
}

variable "contracts" {
  description = "Map of contracts to create. Key is the contract name."
  type = map(object({
    description = optional(string, "")
    scope       = optional(string, "tenant")
    subjects    = optional(list(string), ["default"])
  }))
  default = {}
}
