variable "aci_username" {
  description = "Username for Cisco ACI APIC"
  type        = string
  default     = "admin"
}

variable "aci_password" {
  description = "Password for Cisco ACI APIC"
  type        = string
  sensitive   = true
  default     = "##########"
}

variable "aci_url" {
  description = "URL for Cisco ACI APIC"
  type        = string
  default     = "https://sandboxapicdc.cisco.com" # Should be updated to the Frankfurt APIC URL
}

variable "vlan_pools" {
  description = "VLAN pools to configure"
  type = map(object({
    alloc_mode = string
  }))
  default = {
    "vlan_pool_prod_fra" = {
      alloc_mode = "static"
    }
  }
}
