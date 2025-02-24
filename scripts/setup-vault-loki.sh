#!/bin/bash

# Use the provided root token
ROOT_TOKEN="${VAULT_ROOT_TOKEN}"

echo "Setting up Vault for Loki..."

# Enable KV secrets engine
echo "Enabling KV secrets engine..."
kubectl exec -n security vault-0 -- env VAULT_TOKEN="$ROOT_TOKEN" vault secrets enable kv

# Configure Kubernetes authentication
echo "Configuring Kubernetes authentication..."
kubectl exec -n security vault-0 -- env VAULT_TOKEN="$ROOT_TOKEN" vault auth enable kubernetes

# Get the Kubernetes host
KUBERNETES_HOST="https://kubernetes.default.svc"

# Get the CA certificate
CA_CERT=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 -d)
TOKEN_REVIEWER_JWT=$(kubectl create token vault -n security)

echo "Setting up Kubernetes authentication configuration..."
kubectl exec -n security vault-0 -- env VAULT_TOKEN="$ROOT_TOKEN" vault write auth/kubernetes/config \
    token_reviewer_jwt="$TOKEN_REVIEWER_JWT" \
    kubernetes_host="$KUBERNETES_HOST" \
    kubernetes_ca_cert="$CA_CERT" \
    issuer="https://kubernetes.default.svc.cluster.local"

# Create a policy for Loki
echo "Creating Vault policy for Loki..."
cat <<EOF | kubectl exec -i -n security vault-0 -- env VAULT_TOKEN="$ROOT_TOKEN" vault policy write loki -
path "kv/data/storage/minio" {
  capabilities = ["read"]
}
EOF

# Create a Kubernetes authentication role for Loki
echo "Creating Kubernetes authentication role for Loki..."
kubectl exec -n security vault-0 -- env VAULT_TOKEN="$ROOT_TOKEN" vault write auth/kubernetes/role/loki \
    bound_service_account_names=loki \
    bound_service_account_namespaces=observability \
    policies=loki \
    ttl=1h

# Store MinIO credentials
echo "Storing MinIO credentials in Vault..."
kubectl exec -n security vault-0 -- env VAULT_TOKEN="$ROOT_TOKEN" vault kv put kv/storage/minio \
    access_key_id="minio" \
    secret_access_key="minio123"

echo "Vault setup for Loki completed successfully!" 