variable "static_bindings" {
  description = "Map of EPG static path bindings. Key is a unique binding identifier."
  type = map(object({
    epg_dn               = string
    path_dn              = string
    vlan                 = number
    mode                 = optional(string, "regular")
    deployment_immediacy = optional(string, "lazy")
  }))
  default = {}
}
