variable "vlan_pools" {
  description = "Map of VLAN pools to create. Key is the pool name."
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
