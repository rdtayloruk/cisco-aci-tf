resource "aci_tenant" "this" {
  name        = var.name
  description = var.description
}
