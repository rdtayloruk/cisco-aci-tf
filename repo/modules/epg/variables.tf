variable "tenant_dn" {
  description = "DN of the parent tenant"
  type        = string
}

variable "bd_ids" {
  description = "Map of bridge domain name to DN, from the bd module output"
  type        = map(string)
  default     = {}
}

variable "contract_ids" {
  description = "Map of contract name to DN, from the contract module output"
  type        = map(string)
  default     = {}
}

variable "application_profiles" {
  description = "Map of application profiles. Key is the AP name. Each contains a map of EPGs."
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
