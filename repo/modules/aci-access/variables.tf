variable "vlan_pools" {
  description = "Map of VLAN Pools to create. Key is the pool name."
  type = map(object({
    alloc_mode = string # e.g. "static" or "dynamic"
  }))
  default = {}
}

variable "physical_domains" {
  description = "Map of Physical Domains to create. Key is the domain name."
  type = map(object({
    vlan_pool_name = optional(string)
  }))
  default = {}
}

variable "aaeps" {
  description = "Map of Attachable Access Entity Profiles (AAEPs) to create."
  type        = map(object({}))
  default     = {}
}
