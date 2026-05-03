variable "tenant_name" {
  description = "Name of the ACI Tenant"
  type        = string
}

variable "description" {
  description = "Description for the Tenant"
  type        = string
  default     = "Managed by Terraform GitOps"
}

variable "subnet_ip" {
  description = "IP address and mask for the Bridge Domain Subnet (e.g. 10.1.1.1/24)"
  type        = string
}
