variable "aaeps" {
  description = "Map of Attachable Access Entity Profiles. Key is the AAEP name."
  type = map(object({
    description = optional(string, "")
    domain_dns  = optional(list(string), [])
  }))
  default = {}
}
