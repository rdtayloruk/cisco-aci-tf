# Change Reference
# change_id: CHG000001
# description = "Change ID: CHG000001"

# Tenant
# tenant_name = "ACME"

# VRFs
# vrfs = [
#   "VRF1"
# ]

# Bridge Domains & Subnets
# bridge_domains = {
#   "BD1" = {
#     vrf_name = "VRF1"
#     subnets = {
#       "gateway" = {
#         ip    = "10.1.1.1/24"
#         scope = ["public"]
#       }
#     }
#   }
# }

# Application Profiles & EPGs
# application_profiles = {
#   "APP1" = {
#     epgs = {
#       "WEB" = {
#         bd_name = "BD1"
#       }
#     }
#   }
# }

# -----------------------------------------------------------------------------------------
# Contract and EPG Binding Definitions
# -----------------------------------------------------------------------------------------

# contracts = [
#   "WEB_TO_APP"
# ]

# epg_bindings = {
#   "WEB" = {
#     app_profile   = "APP1"
#     contracts     = [{ name = "WEB_TO_APP", type = "consumer" }]
#     domain_binds  = [{ name = "phys", type = "phys" }]
#   }
# }
