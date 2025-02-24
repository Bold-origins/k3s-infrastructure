#!/bin/bash

# Set up Vault connection
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN=$(kubectl get secret -n security ui-vault-creds -o jsonpath='{.data.vault_root_token}' | base64 -d)

# Start port-forward in the background
echo "Starting Vault port-forward..."
kubectl port-forward -n security svc/vault 8200:8200 &
PORTFORWARD_PID=$!

# Wait for port-forward to be ready
sleep 5

# Enable KV secrets engine if not already enabled
echo "Enabling KV secrets engine..."
vault secrets enable -path=kv kv-v2 || true

# Enable Kubernetes auth if not already enabled
echo "Enabling Kubernetes auth..."
vault auth enable kubernetes || true

# Get the Kubernetes CA certificate
echo "Getting Kubernetes CA certificate..."
kubectl get secret -n security vault-0 -o jsonpath='{.data.token}' > /tmp/vault-k8s-token
kubectl get secret -n security vault-0 -o jsonpath='{.data.ca\.crt}' | base64 -d > /tmp/vault-k8s-ca.crt

# Configure Kubernetes auth
echo "Configuring Kubernetes auth..."
vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc" \
  token_reviewer_jwt="$(cat /tmp/vault-k8s-token)" \
  kubernetes_ca_cert="$(cat /tmp/vault-k8s-ca.crt)" \
  issuer="https://kubernetes.default.svc.cluster.local"

# Create policy
echo "Creating Vault policy for Loki..."
vault policy write loki - <<EOF
path "kv/data/storage/minio" {
  capabilities = ["read"]
}
EOF

# Create Kubernetes auth role
echo "Creating Kubernetes auth role for Loki..."
vault write auth/kubernetes/role/loki \
  bound_service_account_names=loki \
  bound_service_account_namespaces=observability \
  policies=loki \
  ttl=1h

# Store MinIO credentials
echo "Storing MinIO credentials in Vault..."
MINIO_ACCESS_KEY=$(kubectl get secret -n storage minio-credentials -o jsonpath='{.data.root-user}' | base64 -d)
MINIO_SECRET_KEY=$(kubectl get secret -n storage minio-credentials -o jsonpath='{.data.root-password}' | base64 -d)

vault kv put kv/storage/minio \
  access_key_id="$MINIO_ACCESS_KEY" \
  secret_access_key="$MINIO_SECRET_KEY"

# Clean up
echo "Cleaning up..."
rm -f /tmp/vault-k8s-token /tmp/vault-k8s-ca.crt
kill $PORTFORWARD_PID

echo "Setup complete!" 