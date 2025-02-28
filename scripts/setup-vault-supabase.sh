#!/bin/bash

# Use the provided root token
ROOT_TOKEN="${VAULT_ROOT_TOKEN}"

echo "Setting up Vault for Supabase..."

# Set up port-forwarding to access Vault
echo "Setting up port-forwarding to Vault..."
kubectl -n security port-forward svc/vault 8200:8200 &
PF_PID=$!
sleep 2

# Set the Vault address
export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_TOKEN="$ROOT_TOKEN"

# Function to clean up port-forwarding
cleanup() {
  echo "Cleaning up port-forwarding..."
  kill $PF_PID 2>/dev/null || true
}

# Set up trap to clean up on exit
trap cleanup EXIT

# Make sure KV secrets engine is enabled
echo "Enabling KV secrets engine..."
curl -s -X POST -H "X-Vault-Token: $VAULT_TOKEN" \
  -d '{"type": "kv", "options": {"version": "2"}}' \
  http://127.0.0.1:8200/v1/sys/mounts/kv || true

# Configure Kubernetes authentication
if ! curl -s -H "X-Vault-Token: $VAULT_TOKEN" http://127.0.0.1:8200/v1/sys/auth | grep -q kubernetes; then
  echo "Configuring Kubernetes authentication..."
  curl -s -X POST -H "X-Vault-Token: $VAULT_TOKEN" \
    -d '{"type": "kubernetes"}' \
    http://127.0.0.1:8200/v1/sys/auth/kubernetes

  # Get the Kubernetes host
  KUBERNETES_HOST="https://kubernetes.default.svc"

  # Get the CA certificate
  CA_CERT=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 -d)
  TOKEN_REVIEWER_JWT=$(kubectl create token vault -n security)

  echo "Setting up Kubernetes authentication configuration..."
  curl -s -X POST -H "X-Vault-Token: $VAULT_TOKEN" \
    -d "{\"token_reviewer_jwt\": \"$TOKEN_REVIEWER_JWT\", \"kubernetes_host\": \"$KUBERNETES_HOST\", \"kubernetes_ca_cert\": \"$CA_CERT\", \"issuer\": \"https://kubernetes.default.svc.cluster.local\"}" \
    http://127.0.0.1:8200/v1/auth/kubernetes/config
fi

# Create a policy for Supabase
echo "Creating Vault policy for Supabase..."
curl -s -X PUT -H "X-Vault-Token: $VAULT_TOKEN" \
  -d "{\"policy\": \"path \\\"kv/data/supabase/*\\\" { capabilities = [\\\"read\\\"] }\"}" \
  http://127.0.0.1:8200/v1/sys/policies/acl/supabase

# Create a Kubernetes authentication role for Supabase
echo "Creating Kubernetes authentication role for Supabase..."
curl -s -X POST -H "X-Vault-Token: $VAULT_TOKEN" \
  -d "{\"bound_service_account_names\": \"supabase\", \"bound_service_account_namespaces\": \"supabase\", \"policies\": \"supabase\", \"ttl\": \"1h\"}" \
  http://127.0.0.1:8200/v1/auth/kubernetes/role/supabase

# Store Supabase database credentials
echo "Storing Supabase database credentials in Vault..."
curl -s -X POST -H "X-Vault-Token: $VAULT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"data\":{\"username\":\"postgres\",\"password\":\"postgres\",\"database\":\"postgres\"}}" \
  http://127.0.0.1:8200/v1/kv/data/supabase/db

# Store Supabase JWT credentials
echo "Storing Supabase JWT credentials in Vault..."
curl -s -X POST -H "X-Vault-Token: $VAULT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"data\":{\"anonKey\":\"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiJ9.ZopqoUt20nEV9cklpv9e3yw3PVyZLmKs5qLD6nGL1SI\",\"serviceKey\":\"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIn0.M2d2z4SFn5C8xzyEG1McuUivHXzGQVa8QI0XrCU1CIg\",\"secret\":\"super-secret-jwt-token-with-at-least-32-characters\"}}" \
  http://127.0.0.1:8200/v1/kv/data/supabase/jwt

# Store Supabase dashboard credentials
echo "Storing Supabase dashboard credentials in Vault..."
curl -s -X POST -H "X-Vault-Token: $VAULT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"data\":{\"username\":\"admin\",\"password\":\"password\"}}" \
  http://127.0.0.1:8200/v1/kv/data/supabase/dashboard

# Store Supabase SMTP credentials
echo "Storing Supabase SMTP credentials in Vault..."
curl -s -X POST -H "X-Vault-Token: $VAULT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"data\":{\"username\":\"noreply@example.com\",\"password\":\"smtp-password\"}}" \
  http://127.0.0.1:8200/v1/kv/data/supabase/smtp

# Store Supabase analytics credentials
echo "Storing Supabase analytics credentials in Vault..."
curl -s -X POST -H "X-Vault-Token: $VAULT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"data\":{\"apiKey\":\"analytics-api-key\"}}" \
  http://127.0.0.1:8200/v1/kv/data/supabase/analytics

# Store Supabase S3 credentials
echo "Storing Supabase S3 credentials in Vault..."
curl -s -X POST -H "X-Vault-Token: $VAULT_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"data\":{\"accessKey\":\"minio-access-key\",\"keyId\":\"minio-key-id\"}}" \
  http://127.0.0.1:8200/v1/kv/data/supabase/s3

echo "Vault setup for Supabase completed successfully!" 