#!/bin/bash
# Import existing Cisco ACI resources into Terraform state for all environments.
# Prerequisites: Gitea is running, bootstrap.sh has been executed, and jq + terraform are on PATH.
#
# Required env var:
#   ACI_PASSWORD          - APIC admin password
#
# Optional env vars:
#   ACI_USERNAME          - APIC username (default: admin)
#   ACI_URL               - Default APIC URL for all environments
#   ACI_URL_DEV           - Override APIC URL for dev  (default: ACI_URL → sandbox)
#   GITEA_URL             - Gitea base URL            (default: http://localhost:3000)
#   GITEA_ORG             - Gitea organisation        (default: cisco-aci)
#   GITEA_USER            - Gitea username for state  (default: cisco-aci-admin)
#   GITEA_PASSWORD        - Gitea password for state  (default: Admin123!)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${SCRIPT_DIR}/../repo"

# --------------------------------------------------------------------------
# Credentials
# --------------------------------------------------------------------------
ACI_USERNAME="${ACI_USERNAME:-admin}"
ACI_PASSWORD="${ACI_PASSWORD:?ACI_PASSWORD must be set}"

_default_apic="${ACI_URL:-https://sandboxapicdc.cisco.com}"
ACI_URL_DEV="${ACI_URL_DEV:-${_default_apic}}"
ACI_URL_PROD_LON="${ACI_URL_PROD_LON:-${_default_apic}}"
ACI_URL_PROD_FRA="${ACI_URL_PROD_FRA:-${_default_apic}}"

GITEA_URL="${GITEA_URL:-http://localhost:3000}"
GITEA_ORG="${GITEA_ORG:-cisco-aci}"
GITEA_USER="${GITEA_USER:-cisco-aci-admin}"
GITEA_PASSWORD="${GITEA_PASSWORD:-Admin123!}"

# --------------------------------------------------------------------------
# Logging
# --------------------------------------------------------------------------
_g='\033[0;32m' _y='\033[1;33m' _r='\033[0;31m' _n='\033[0m'
info()  { printf "${_g}[INFO]${_n}  %s\n" "$*"; }
warn()  { printf "${_y}[WARN]${_n}  %s\n" "$*"; }
error() { printf "${_r}[ERROR]${_n} %s\n" "$*"; }

# --------------------------------------------------------------------------
# APIC REST helpers
# --------------------------------------------------------------------------

apic_login() {
    local url="$1"
    curl -sk -X POST "${url}/api/aaaLogin.json" \
        -H "Content-Type: application/json" \
        -d "{\"aaaUser\":{\"attributes\":{\"name\":\"${ACI_USERNAME}\",\"pwd\":\"${ACI_PASSWORD}\"}}}" \
        | jq -r '.imdata[0].aaaLogin.attributes.token // empty'
}

dn_exists() {
    local url="$1" token="$2" dn="$3"
    local count
    count=$(curl -sk "${url}/api/node/mo/${dn}.json" \
        -H "Cookie: APIC-cookie=${token}" \
        | jq -r '.totalCount // "0"')
    [[ "${count}" != "0" ]]
}

# --------------------------------------------------------------------------
# Terraform helpers
# --------------------------------------------------------------------------

tf_init() {
    local dir="$1" state_key="$2"
    local addr="${GITEA_URL}/api/packages/${GITEA_ORG}/terraform/state/${state_key}"
    info "  init → state key: ${state_key}"
    (cd "${dir}" && terraform init \
        -backend-config="address=${addr}" \
        -backend-config="lock_address=${addr}" \
        -backend-config="unlock_address=${addr}" \
        -backend-config="username=${GITEA_USER}" \
        -backend-config="password=${GITEA_PASSWORD}" \
        -reconfigure -input=false -no-color 2>&1 \
        | grep -E '(Terraform has been|Error|error)' || true)
}

# Evaluate a Terraform expression against variable defaults in a directory
tf_console() {
    local dir="$1" expr="$2"
    (cd "${dir}" && \
        TF_VAR_aci_username="${ACI_USERNAME}" \
        TF_VAR_aci_password="${ACI_PASSWORD}" \
        terraform console -no-color 2>/dev/null <<< "${expr}" | tr -d '"')
}

# Import one resource; skip silently if already present in state
tf_import() {
    local dir="$1" address="$2" id="$3"
    printf "    %-65s" "${address}"
    if (cd "${dir}" && terraform state show "${address}" > /dev/null 2>&1); then
        echo "(already in state)"
        return 0
    fi
    if (cd "${dir}" && \
        TF_VAR_aci_username="${ACI_USERNAME}" \
        TF_VAR_aci_password="${ACI_PASSWORD}" \
        terraform import -no-color -input=false "${address}" "${id}" > /dev/null 2>&1); then
        echo "imported"
    else
        echo "FAILED (check DN or provider connectivity)"
    fi
}

# --------------------------------------------------------------------------
# Tenant component
# --------------------------------------------------------------------------

import_tenants() {
    local env="$1" apic_url="$2" token="$3"
    local dir="${REPO_DIR}/environments/${env}/tenants"
    [[ -d "${dir}" ]] || return 0

    tf_init "${dir}" "${env}-tenants"

    local tenant_name tenant_dn
    tenant_name=$(tf_console "${dir}" 'var.tenant_name')
    tenant_dn="uni/tn-${tenant_name}"

    if ! dn_exists "${apic_url}" "${token}" "${tenant_dn}"; then
        warn "  Tenant '${tenant_name}' not found in APIC — skipping"
        return 0
    fi
    info "  Tenant: ${tenant_name}"

    tf_import "${dir}" "module.tenant.aci_tenant.main" "${tenant_dn}"

    # VRFs
    local vrfs_csv
    vrfs_csv=$(tf_console "${dir}" 'join(",", tolist(var.vrfs))')
    IFS=',' read -ra _vrfs <<< "${vrfs_csv}"
    for vrf in "${_vrfs[@]}"; do
        vrf="${vrf// /}"
        [[ -z "${vrf}" ]] && continue
        dn_exists "${apic_url}" "${token}" "uni/tn-${tenant_name}/ctx-${vrf}" && \
            tf_import "${dir}" "module.tenant.aci_vrf.main[\"${vrf}\"]" \
                      "uni/tn-${tenant_name}/ctx-${vrf}" || true
    done

    # Bridge Domains + Subnets
    local bd_json
    bd_json=$(cd "${dir}" && TF_VAR_aci_password="${ACI_PASSWORD}" \
        terraform console -no-color 2>/dev/null \
        <<< 'jsonencode({for k, v in var.bridge_domains : k => {subnets: {for sk, sv in v.subnets : sk => sv.ip}}})')

    while IFS= read -r bd; do
        [[ -z "${bd}" ]] && continue
        dn_exists "${apic_url}" "${token}" "uni/tn-${tenant_name}/BD-${bd}" && \
            tf_import "${dir}" "module.tenant.aci_bridge_domain.main[\"${bd}\"]" \
                      "uni/tn-${tenant_name}/BD-${bd}" || true

        while IFS=' ' read -r sk ip; do
            dn_exists "${apic_url}" "${token}" "uni/tn-${tenant_name}/BD-${bd}/subnet-[${ip}]" && \
                tf_import "${dir}" "module.tenant.aci_subnet.main[\"${bd}_${sk}\"]" \
                          "uni/tn-${tenant_name}/BD-${bd}/subnet-[${ip}]" || true
        done < <(echo "${bd_json}" | jq -r --arg bd "${bd}" \
            '.[$bd].subnets // {} | to_entries[] | "\(.key) \(.value)"')
    done < <(echo "${bd_json}" | jq -r 'keys[]')

    # Application Profiles + EPGs
    local ap_json
    ap_json=$(cd "${dir}" && TF_VAR_aci_password="${ACI_PASSWORD}" \
        terraform console -no-color 2>/dev/null \
        <<< 'jsonencode({for k, v in var.application_profiles : k => keys(v.epgs)})')

    while IFS= read -r ap; do
        [[ -z "${ap}" ]] && continue
        dn_exists "${apic_url}" "${token}" "uni/tn-${tenant_name}/ap-${ap}" && \
            tf_import "${dir}" "module.tenant.aci_application_profile.main[\"${ap}\"]" \
                      "uni/tn-${tenant_name}/ap-${ap}" || true

        while IFS= read -r epg; do
            [[ -z "${epg}" ]] && continue
            dn_exists "${apic_url}" "${token}" "uni/tn-${tenant_name}/ap-${ap}/epg-${epg}" && \
                tf_import "${dir}" "module.tenant.aci_application_epg.main[\"${ap}_${epg}\"]" \
                          "uni/tn-${tenant_name}/ap-${ap}/epg-${epg}" || true
        done < <(echo "${ap_json}" | jq -r --arg ap "${ap}" '.[$ap][]')
    done < <(echo "${ap_json}" | jq -r 'keys[]')
}

# --------------------------------------------------------------------------
# Access-policies component
# --------------------------------------------------------------------------

import_access_policies() {
    local env="$1" apic_url="$2" token="$3"
    local dir="${REPO_DIR}/environments/${env}/access-policies"
    [[ -d "${dir}" ]] || return 0

    tf_init "${dir}" "${env}-access-policies"

    local pool_json
    pool_json=$(cd "${dir}" && TF_VAR_aci_password="${ACI_PASSWORD}" \
        terraform console -no-color 2>/dev/null \
        <<< 'jsonencode({for k, v in var.vlan_pools : k => v.alloc_mode})')

    while IFS= read -r pool; do
        [[ -z "${pool}" ]] && continue
        local alloc_mode
        alloc_mode=$(echo "${pool_json}" | jq -r --arg p "${pool}" '.[$p]')
        dn_exists "${apic_url}" "${token}" "uni/infra/vlanns-[${pool}]-${alloc_mode}" && \
            tf_import "${dir}" "module.access_policies.aci_vlan_pool.main[\"${pool}\"]" \
                      "uni/infra/vlanns-[${pool}]-${alloc_mode}" || true
    done < <(echo "${pool_json}" | jq -r 'keys[]')
}

# --------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------

echo "==================================================================="
echo "  ACI Terraform State Import"
echo "==================================================================="
echo ""

declare -A _apic_urls=(
    ["dev"]="${ACI_URL_DEV}"
)

for env in dev; do
    apic_url="${_apic_urls[${env}]}"
    echo "=== ${env} (APIC: ${apic_url}) ==="

    info "Authenticating with APIC..."
    token=$(apic_login "${apic_url}")
    if [[ -z "${token}" ]]; then
        error "Authentication failed for ${env} — skipping."
        echo ""
        continue
    fi
    info "Authenticated."

    import_tenants         "${env}" "${apic_url}" "${token}"
    import_access_policies "${env}" "${apic_url}" "${token}"
    echo ""
done

echo "==================================================================="
echo "  Done. Run 'terraform plan' in each environment directory to verify."
echo "==================================================================="
