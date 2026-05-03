terraform {
  required_providers {
    aci = {
      source = "CiscoDevNet/aci"
    }
  }
}

resource "aci_tenant" "tenant" {
  name        = var.tenant_name
  description = var.description
}

resource "aci_vrf" "vrf" {
  tenant_dn = aci_tenant.tenant.id
  name      = "${var.tenant_name}_vrf"
}

resource "aci_bridge_domain" "bd" {
  tenant_dn          = aci_tenant.tenant.id
  relation_fv_rs_ctx = aci_vrf.vrf.id
  name               = "${var.tenant_name}_bd"
}

resource "aci_subnet" "subnet" {
  parent_dn        = aci_bridge_domain.bd.id
  ip               = var.subnet_ip
  scope            = ["public"]
}

resource "aci_application_profile" "ap" {
  tenant_dn = aci_tenant.tenant.id
  name      = "${var.tenant_name}_ap"
}

resource "aci_application_epg" "epg" {
  application_profile_dn = aci_application_profile.ap.id
  name                   = "${var.tenant_name}_epg"
  relation_fv_rs_bd      = aci_bridge_domain.bd.id
}
