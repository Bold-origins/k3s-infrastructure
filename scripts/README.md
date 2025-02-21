# Secret Management Scripts

This directory contains scripts to help manage secrets in the k3s infrastructure using sealed-secrets.

## Prerequisites

- `kubeseal` CLI tool installed
- Access to the Kubernetes cluster
- Sealed Secrets controller running in the cluster
- `jq` command-line JSON processor (for some scripts)

## Initial Setup

1. Copy the example credentials file:
```bash
cp ui-credentials.txt.example ui-credentials.txt
```

2. Edit the credentials file with your actual values:
```bash
vim ui-credentials.txt
```

3. Set required environment variables:
```bash
export VAULT_TOKEN='your-vault-token'
```

## Available Scripts

### 1. list-namespaces.sh

Lists all namespaces with their purposes.

```bash
# Make the script executable
chmod +x list-namespaces.sh

# List all namespaces with their purposes
./list-namespaces.sh

# Get JSON output
./list-namespaces.sh -o json
```

Options:
- `-o`: Output format: text (default) or json
- `-h`: Show help message

Key Namespaces:
- `infra`: Core infrastructure (cert-manager, ingress-nginx, sealed-secrets)
- `observability`: Monitoring stack (Prometheus, Grafana, Loki)
- `security`: Security tools (Vault, Falco, Gatekeeper)
- `storage`: Storage solutions (MinIO)
- `flux-system`: Flux GitOps components

### 2. seal-secret.sh

Seals a single key-value secret.

```bash
# Make the script executable
chmod +x seal-secret.sh

# Example usage
./seal-secret.sh -n my-namespace -s my-secret -k username -v admin
./seal-secret.sh -n my-namespace -s my-secret -k password -v mysecret -f output.yaml
```

Options:
- `-n`: Namespace for the secret (required)
- `-s`: Secret name (required)
- `-k`: Key in the secret (required)
- `-v`: Value for the key (required)
- `-f`: Output file (optional, defaults to sealed-secret.yaml)
- `-h`: Show help message

### 3. seal-multi-secret.sh

Seals multiple key-value pairs from a file.

```bash
# Make the script executable
chmod +x seal-multi-secret.sh

# Create a values file
cat > values.txt << EOF
username=admin
password=mysecret
api_key=1234567890
EOF

# Seal the secret
./seal-multi-secret.sh -n my-namespace -s my-secret -f values.txt -o output.yaml
```

Options:
- `-n`: Namespace for the secret (required)
- `-s`: Secret name (required)
- `-f`: File containing key-value pairs (required)
- `-o`: Output file (optional, defaults to sealed-secret.yaml)
- `-h`: Show help message

### 4. get-secret.sh

Retrieves and decodes Kubernetes secrets.

```bash
# Make the script executable
chmod +x get-secret.sh

# Get all keys in a secret
./get-secret.sh -n my-namespace -s my-secret

# Get a specific key
./get-secret.sh -n my-namespace -s my-secret -k username

# Get output in JSON format
./get-secret.sh -n my-namespace -s my-secret -o json
```

Options:
- `-n`: Namespace of the secret (required)
- `-s`: Secret name (required)
- `-k`: Specific key to retrieve (optional)
- `-o`: Output format: text or json (optional, defaults to text)
- `-h`: Show help message

### 5. list-secrets.sh

Lists all secrets with detailed information.

```bash
# Make the script executable
chmod +x list-secrets.sh

# List all secrets in all namespaces
./list-secrets.sh

# List secrets in a specific namespace
./list-secrets.sh -n my-namespace

# List TLS secrets with detailed view
./list-secrets.sh -t kubernetes.io/tls -o wide

# Get JSON output
./list-secrets.sh -n my-namespace -o json
```

Options:
- `-n`: Namespace to list secrets from (optional, defaults to all namespaces)
- `-t`: Filter by secret type (optional)
- `-o`: Output format: text, wide, or json (optional, defaults to text)
- `-h`: Show help message

### 6. store-ui-credentials.sh

Stores UI credentials in both Sealed Secrets and Vault.

```bash
# Make the script executable
chmod +x store-ui-credentials.sh

# Set required environment variables
export VAULT_TOKEN='your-vault-token'

# Store credentials using default credentials file
./store-ui-credentials.sh

# Store credentials using custom credentials file
./store-ui-credentials.sh -f my-credentials.txt
```

Options:
- `-f`: Credentials file (optional, defaults to scripts/ui-credentials.txt)
- `-h`: Show help message

Required Environment Variables:
- `VAULT_TOKEN`: Vault root token for authentication

## Examples

1. Create and retrieve a basic secret:
```bash
# List available namespaces
./list-namespaces.sh

# Create the secret in the observability namespace
./seal-secret.sh -n observability -s grafana-creds -k admin-password -v mysecret

# Retrieve the secret
./get-secret.sh -n observability -s grafana-creds -k admin-password
```

2. Create and list multi-key secrets:
```bash
# Create values file
cat > db-creds.txt << EOF
username=dbuser
password=dbpass
host=db.example.com
port=5432
EOF

# Create the secret in the storage namespace
./seal-multi-secret.sh -n storage -s db-credentials -f db-creds.txt

# List secrets in the namespace
./list-secrets.sh -n storage -o wide

# Retrieve all values
./get-secret.sh -n storage -s db-credentials -o json
```

3. Work with different secret types:
```bash
# List all TLS secrets
./list-secrets.sh -t kubernetes.io/tls -o wide

# List all secrets in JSON format
./list-secrets.sh -o json
```

## Notes

- The sealed secrets can be safely committed to Git
- The secrets can only be decrypted by the sealed-secrets controller in your cluster
- Make sure to keep your values files secure and don't commit them to Git
- The `get-secret.sh` script requires appropriate RBAC permissions to read secrets
- Use `list-secrets.sh` with caution in production environments as it may expose sensitive information
- Always check the namespace with `list-namespaces.sh` before creating secrets to ensure proper placement
- Never commit actual credentials to Git, use the example files as templates
- Store sensitive environment variables in a secure location (e.g., .env file not tracked by Git) 