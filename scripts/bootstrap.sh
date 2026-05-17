#!/bin/bash
set -e

echo "Waiting for Gitea to start..."
while ! curl -s http://localhost:3000/ > /dev/null 2>&1; do
    echo "Gitea is unavailable - sleeping"
    sleep 3
done
echo "Gitea is up!"

# Wait a little bit for the DB to be fully ready
sleep 5

# 1. Create cisco-aci-admin user (this will also skip the install lock if it's the first admin)
echo "Creating admin user..."
docker exec -u git gitea gitea admin user create --username cisco-aci-admin --password 'Admin123!' --email cisco-aci-admin@example.com --admin || echo "Admin may already exist."

# 2. Create cisco-aci-user
echo "Creating standard user..."
docker exec -u git gitea gitea admin user create --username cisco-aci-user --password 'User123!' --email cisco-aci-user@example.com || echo "User may already exist."

# 3. Use API to create organization, as gitea CLI doesn't have an 'admin org create' command
echo "Creating cisco-aci organization..."
curl -s -X POST "http://localhost:3000/api/v1/orgs" \
    -H "accept: application/json" -H "Content-Type: application/json" \
    -u cisco-aci-admin:'Admin123!' \
    -d '{
        "username": "cisco-aci",
        "visibility": "public",
        "description": "Cisco ACI GitOps"
    }' || echo "Org creation failed (might already exist)."

# 4. Create cisco-aci-tf repository inside the organization
echo "Creating cisco-aci-tf repository..."
curl -s -X POST "http://localhost:3000/api/v1/orgs/cisco-aci/repos" \
    -H "accept: application/json" -H "Content-Type: application/json" \
    -u cisco-aci-admin:'Admin123!' \
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
while ! curl -s -f http://localhost:3000/api/v1/version > /dev/null 2>&1; do
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
    # Ensure the container network is set to cisco-aci-tf_gitea so jobs can access Gitea as 'server'
    sed -i 's/network: ""/network: "cisco-aci-tf_gitea"/g' runner_data/config.yaml
    # Fix ownership of the generated files to the host user
    docker run --rm -v "$(pwd)/runner_data:/data" alpine chown -R "$(id -u):$(id -g)" /data || true
fi

echo "Registering Runner..."
# Register the runner in the runner container
docker exec gitea-runner act_runner register --instance http://server:3000 --token "$TOKEN" --no-interactive --name local-runner || echo "Runner may already be registered."

echo "Restarting Runner..."
docker restart gitea-runner

echo "Bootstrap completed."
echo ""

# Optionally import existing ACI state into each environment's Terraform backend.
# This step requires ACI_PASSWORD to be set and the APIC to be reachable.
if [ -n "${ACI_PASSWORD:-}" ]; then
    echo "ACI_PASSWORD is set — running state import from APIC..."
    bash "$(dirname "$0")/import-state.sh"
else
    echo "To import existing ACI resources into Terraform state, run:"
    echo "  ACI_PASSWORD=<apic-password> ./scripts/import-state.sh"
    echo ""
    echo "Optional overrides (see import-state.sh for the full list):"
    echo "  ACI_USERNAME=admin ACI_URL=https://<apic-host> ACI_PASSWORD=... ./scripts/import-state.sh"
fi
