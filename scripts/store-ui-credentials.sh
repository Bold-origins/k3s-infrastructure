#!/bin/bash

# Help function
show_help() {
    echo "Usage: $0 [-f CREDENTIALS_FILE]"
    echo
    echo "Store UI credentials in both Sealed Secrets and Vault"
    echo
    echo "Optional arguments:"
    echo "  -f CREDENTIALS_FILE  File containing credentials (default: scripts/ui-credentials.txt)"
    echo "  -h                  Show this help message"
    echo
    echo "Required environment variables:"
    echo "  VAULT_TOKEN         Vault root token for authentication"
    exit 1
}

# Parse arguments
while getopts "f:h" opt; do
    case $opt in
        f) CREDS_FILE="$OPTARG";;
        h) show_help;;
        \?) echo "Invalid option -$OPTARG" >&2; exit 1;;
    esac
done

# Check for required environment variables
if [ -z "$VAULT_TOKEN" ]; then
    echo "Error: VAULT_TOKEN environment variable is required"
    exit 1
fi

# Set default credentials file if not specified
CREDS_FILE=${CREDS_FILE:-"scripts/ui-credentials.txt"}

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# If CREDS_FILE is a relative path and file doesn't exist, try looking relative to SCRIPT_DIR
if [[ ! -f "$CREDS_FILE" && ! "$CREDS_FILE" =~ ^/ ]]; then
    CREDS_FILE="$SCRIPT_DIR/$(basename "$CREDS_FILE")"
fi

# Check if credentials file exists
if [ ! -f "$CREDS_FILE" ]; then
    echo "Error: Credentials file '$CREDS_FILE' not found"
    exit 1
fi

# Create sealed secrets for each component
echo "Creating sealed secrets..."

# Function to extract credentials by prefix
extract_credentials() {
    local prefix="$1"
    local tempfile=$(mktemp)
    
    grep "^${prefix}_" "$CREDS_FILE" > "$tempfile"
    echo "$tempfile"
}

# Ensure we're in the repository root directory
cd "$SCRIPT_DIR/.." || exit 1

# Grafana credentials (observability namespace)
echo "Creating Grafana sealed secret..."
grafana_creds=$(extract_credentials "grafana")
./scripts/seal-multi-secret.sh -n observability -s ui-grafana-creds -f "$grafana_creds" -o cluster/observability/secrets/sealed-ui-credentials.yaml
rm "$grafana_creds"

# MinIO credentials (storage namespace)
echo "Creating MinIO sealed secret..."
minio_creds=$(extract_credentials "minio")
./scripts/seal-multi-secret.sh -n storage -s ui-minio-creds -f "$minio_creds" -o cluster/storage/secrets/sealed-ui-credentials.yaml
rm "$minio_creds"

# Vault credentials (security namespace)
echo "Creating Vault sealed secret..."
vault_creds=$(extract_credentials "vault")
./scripts/seal-multi-secret.sh -n security -s ui-vault-creds -f "$vault_creds" -o cluster/security/secrets/sealed-ui-credentials.yaml
rm "$vault_creds"

echo "Sealed secrets created successfully!"

# Store in Vault (if Vault is available)
if kubectl -n security get pod vault-0 &>/dev/null; then
    echo "Storing credentials in Vault..."
    
    # Check if Vault port-forward is running
    if ! nc -z localhost 8200 2>/dev/null; then
        echo "Starting Vault port-forward..."
        kubectl -n security port-forward svc/vault 8200:8200 &
        sleep 2
    fi
    
    # Set Vault address
    export VAULT_ADDR='http://127.0.0.1:8200'
    
    # Function to create JSON for a specific service
    create_service_json() {
        local prefix="$1"
        local json_data="{"
        while IFS='=' read -r key value; do
            # Skip empty lines and comments
            [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
            
            # Only process keys with the correct prefix
            [[ "$key" != ${prefix}_* ]] && continue
            
            # Remove prefix from key
            local short_key=${key#${prefix}_}
            
            # Remove any leading/trailing whitespace
            value=$(echo "$value" | xargs)
            
            # Add to JSON
            json_data="$json_data\"$short_key\":\"$value\","
        done < "$CREDS_FILE"
        json_data="${json_data%,}}"
        echo "$json_data"
    }
    
    # Enable KV secrets engine if not already enabled
    echo "Enabling KV secrets engine..."
    curl -s -X POST -H "X-Vault-Token: $VAULT_TOKEN" \
        -d '{"type": "kv", "options": {"version": "2"}}' \
        http://127.0.0.1:8200/v1/sys/mounts/kv || true
    
    # Store credentials for each service in its own path
    echo "Storing Grafana credentials..."
    grafana_json=$(create_service_json "grafana")
    echo "$grafana_json" | curl -s -X POST -H "X-Vault-Token: $VAULT_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"data\":$grafana_json}" \
        http://127.0.0.1:8200/v1/kv/data/ui/grafana
    
    echo "Storing MinIO credentials..."
    minio_json=$(create_service_json "minio")
    echo "$minio_json" | curl -s -X POST -H "X-Vault-Token: $VAULT_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"data\":$minio_json}" \
        http://127.0.0.1:8200/v1/kv/data/ui/minio
    
    echo "Storing Vault credentials..."
    vault_json=$(create_service_json "vault")
    echo "$vault_json" | curl -s -X POST -H "X-Vault-Token: $VAULT_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"data\":$vault_json}" \
        http://127.0.0.1:8200/v1/kv/data/ui/vault
    
    echo "Credentials stored in Vault successfully!"
    echo
    echo "You can retrieve credentials from Vault using:"
    echo "  - Grafana: vault kv get kv/ui/grafana"
    echo "  - MinIO: vault kv get kv/ui/minio"
    echo "  - Vault: vault kv get kv/ui/vault"
else
    echo "Warning: Vault is not available. Credentials were only stored as sealed secrets."
fi

echo "Done! UI credentials have been stored securely." 