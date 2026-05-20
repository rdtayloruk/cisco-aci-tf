#!/bin/bash
set -e

# Load .env file if it exists and we're not running via Make (which already exports them)
if [ -f "$(dirname "$0")/../.env" ]; then
    echo "Loading local environment variables from .env..."
    # Filter out comments and empty lines before exporting
    export $(grep -v '^#' "$(dirname "$0")/../.env" | grep -v '^[[:space:]]*$' | xargs)
fi

# --------------------------------------------------------------------------
# Environment & Defaults
# --------------------------------------------------------------------------
ACI_USERNAME="${ACI_USERNAME:-admin}"
ACI_PASSWORD="${ACI_PASSWORD:-}"
_default_apic="${ACI_URL:-https://sandboxapicdc.cisco.com}"
ACI_URL_DEV="${ACI_URL_DEV:-${_default_apic}}"

GITEA_URL="${GITEA_URL:-http://localhost:3000}"
GITEA_ORG="${GITEA_ORG:-cisco-aci}"
GITEA_USER="${GITEA_USER:-cisco-aci-admin}"
GITEA_PASSWORD="${GITEA_PASSWORD:-Admin123!}"

TF_HTTP_USERNAME="${TF_HTTP_USERNAME:-${GITEA_USER}}"
TF_HTTP_PASSWORD="${TF_HTTP_PASSWORD:-${GITEA_PASSWORD}}"

echo "Waiting for Gitea to start..."
while ! curl -s "${GITEA_URL}/" > /dev/null 2>&1; do
    echo "Gitea is unavailable - sleeping"
    sleep 3
done
echo "Gitea is up!"

# Wait a little bit for the DB to be fully ready
sleep 5

# 1. Create Gitea admin user (this will also skip the install lock if it's the first admin)
echo "Creating admin user '${GITEA_USER}'..."
docker exec -u git gitea gitea admin user create --username "${GITEA_USER}" --password "${GITEA_PASSWORD}" --email "${GITEA_USER}@example.com" --admin || echo "Admin may already exist."

# 2. Create cisco-aci-user (standard user demo)
echo "Creating standard user 'cisco-aci-user'..."
docker exec -u git gitea gitea admin user create --username cisco-aci-user --password 'User123!' --email cisco-aci-user@example.com || echo "User may already exist."

# 3. Use API to create organization, as gitea CLI doesn't have an 'admin org create' command
echo "Creating '${GITEA_ORG}' organization..."
curl -s -X POST "${GITEA_URL}/api/v1/orgs" \
    -H "accept: application/json" -H "Content-Type: application/json" \
    -u "${GITEA_USER}":"${GITEA_PASSWORD}" \
    -d "{
        \"username\": \"${GITEA_ORG}\",
        \"visibility\": \"public\",
        \"description\": \"Cisco ACI GitOps\"
    }" || echo "Org creation failed (might already exist)."

# 4. Create cisco-aci-tf repository inside the organization
echo "Creating cisco-aci-tf repository in '${GITEA_ORG}'..."
curl -s -X POST "${GITEA_URL}/api/v1/orgs/${GITEA_ORG}/repos" \
    -H "accept: application/json" -H "Content-Type: application/json" \
    -u "${GITEA_USER}":"${GITEA_PASSWORD}" \
    -d '{
        "name": "cisco-aci-tf",
        "description": "Terraform configuration for Cisco ACI",
        "private": false,
        "auto_init": true,
        "default_branch": "main"
    }' || echo "Repo creation failed (might already exist)."

# 5. Enable Actions globally and on the repository
# We need to make sure actions are enabled. By default in new Gitea versions they might not be enabled.
# We will modify the app.ini to ensure actions are enabled.
echo "Enabling Actions in Gitea configuration..."
docker exec -u git -w /tmp gitea gitea cert --host localhost || true # ensure certs if needed, not usually for http
docker exec -u git gitea sed -i '/\[actions\]/d' /data/gitea/conf/app.ini || true
docker exec -u git gitea sed -i '/ENABLED = /d' /data/gitea/conf/app.ini || true
echo -e "\n[actions]\nENABLED = true\n" | docker exec -i -u git gitea tee -a /data/gitea/conf/app.ini > /dev/null
echo "Restarting Gitea to apply actions configuration..."
docker restart gitea

echo "Waiting for Gitea to restart..."
while ! curl -s -f "${GITEA_URL}/api/v1/version" > /dev/null 2>&1; do
    sleep 3
done
sleep 5

# 6. Generate Runner token and register runner
echo "Generating Actions Runner token..."
TOKEN=$(docker exec -u git gitea gitea --config /data/gitea/conf/app.ini forgejo-cli actions generate-runner-token || docker exec -u git gitea gitea actions generate-runner-token)

echo "Runner Token: $TOKEN"

if [ ! -f "runner_data/config.yaml" ]; then
    echo "Generating runner configuration..."
    mkdir -p runner_data
    docker run --rm --entrypoint "" -v "$(pwd)/runner_data:/data" gitea/act_runner:latest sh -c "act_runner generate-config > /data/config.yaml"
    # Fix ownership of the generated files to the host user
    docker run --rm -v "$(pwd)/runner_data:/data" alpine chown -R "$(id -u):$(id -g)" /data || true
    # Ensure the container network is set to cisco-aci-tf_gitea so jobs can access Gitea as 'server'
    sed -i 's/network: ""/network: "cisco-aci-tf_gitea"/g' runner_data/config.yaml
fi

echo "Registering Runner..."
# Register the runner in the runner container
docker exec gitea-runner act_runner register --instance http://server:3000 --token "$TOKEN" --no-interactive --name local-runner || echo "Runner may already be registered."

echo "Restarting Runner..."
docker restart gitea-runner

# 7. Configure Gitea Action Secrets automatically
# --------------------------------------------------------------------------
# Configure Repository Secrets
# --------------------------------------------------------------------------
set_gitea_secret() {
    local name="$1"
    local value="$2"
    
    if [ -z "$value" ]; then
        echo "  [SKIP] Secret ${name} is empty"
        return 0
    fi
    
    echo "  Configuring Secret: ${name}..."
    local status
    status=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "${GITEA_URL}/api/v1/repos/${GITEA_ORG}/cisco-aci-tf/actions/secrets/${name}" \
        -H "accept: application/json" -H "Content-Type: application/json" \
        -u "${GITEA_USER}:${GITEA_PASSWORD}" \
        -d "{\"data\": \"${value}\"}")
        
    if [ "$status" -eq 201 ] || [ "$status" -eq 204 ]; then
        echo "    Secret ${name} configured successfully (HTTP ${status})."
    else
        echo "    Warning: Failed to set secret ${name} (HTTP ${status})."
    fi
}

echo "Configuring Gitea Actions secrets for repository '${GITEA_ORG}/cisco-aci-tf'..."
set_gitea_secret "ACI_USERNAME" "${ACI_USERNAME}"
set_gitea_secret "ACI_PASSWORD" "${ACI_PASSWORD}"
set_gitea_secret "ACI_URL" "${ACI_URL_DEV}"
set_gitea_secret "TF_HTTP_USERNAME" "${TF_HTTP_USERNAME}"
set_gitea_secret "TF_HTTP_PASSWORD" "${TF_HTTP_PASSWORD}"

echo "Bootstrap completed."
echo ""
