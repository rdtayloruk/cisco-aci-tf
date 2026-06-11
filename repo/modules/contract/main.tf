resource "aci_contract" "this" {
  for_each    = var.contracts
  tenant_dn   = var.tenant_dn
  name        = each.key
  scope       = each.value.scope
  description = each.value.description
}

locals {
  subjects = flatten([
    for cn, c in var.contracts : [
      for s in c.subjects : {
        key           = "${cn}/${s}"
        contract_name = cn
        name          = s
      }
    ]
  ])
}

resource "aci_contract_subject" "this" {
  for_each    = { for s in local.subjects : s.key => s }
  contract_dn = aci_contract.this[each.value.contract_name].id
  name        = each.value.name
}
