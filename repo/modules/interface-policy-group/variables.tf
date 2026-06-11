variable "aaep_ids" {
  description = "Map of AAEP name to DN, from the aaep module output"
  type        = map(string)
  default     = {}
}

variable "interface_policy_groups" {
  description = "Map of interface policy groups. Key is the policy group name. Type must be access, pc, or vpc."
  type = map(object({
    type        = string
    description = optional(string, "")
    aaep_name   = optional(string)
  }))
  default = {}
}
