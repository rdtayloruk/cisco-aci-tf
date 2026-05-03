terraform {
  required_providers {
    aci = {
      source  = "CiscoDevNet/aci"
      version = ">= 2.0.0"
    }
  }
  backend "http" {
    # The URL and credentials will be provided by Gitea Actions environment variables
    # url = "http://server:3000/api/packages/cisco-aci/terraform/state/staging"
    # lock_method = "POST"
    # unlock_method = "DELETE"
  }
}

provider "aci" {
  # Cisco DevNet Always-On Sandbox credentials
  username = var.aci_username
  password = var.aci_password
  url      = var.aci_url
  insecure = true
}

variable "aci_username" {
  type    = string
  default = "admin"
}

variable "aci_password" {
  type    = string
  default = "##########"
}

variable "aci_url" {
  type    = string
  default = "https://sandboxapicdc.cisco.com"
}
