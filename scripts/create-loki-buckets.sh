#!/bin/bash
set -e

# Extract MinIO credentials from the Kubernetes secret
MINIO_ROOT_USER=$(kubectl get secret -n storage minio-credentials -o jsonpath='{.data.root-user}' | base64 -d)
MINIO_ROOT_PASSWORD=$(kubectl get secret -n storage minio-credentials -o jsonpath='{.data.root-password}' | base64 -d)

echo "Retrieved MinIO credentials from Kubernetes secret"

# Clean up any existing pod
echo "Cleaning up any existing minio-client pod..."
kubectl delete pod -n storage minio-client --ignore-not-found

# Start a temporary pod with the MinIO client
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: minio-client
  namespace: storage
spec:
  containers:
  - name: minio-client
    image: minio/mc
    command: 
      - sleep
      - "3600"
    env:
    - name: MINIO_ROOT_USER
      value: $MINIO_ROOT_USER
    - name: MINIO_ROOT_PASSWORD
      value: $MINIO_ROOT_PASSWORD
  restartPolicy: Never
EOF

echo "Waiting for MinIO client pod to be ready..."
kubectl wait --for=condition=Ready pod/minio-client -n storage --timeout=120s

# Execute commands to create buckets
echo "Configuring MinIO client and creating buckets..."
kubectl exec -it -n storage minio-client -- /bin/sh -c "
# Configure the MinIO client
mc alias set myminio http://minio.storage.svc.cluster.local:9000 \$MINIO_ROOT_USER \$MINIO_ROOT_PASSWORD

# Create the buckets required by Loki
mc mb --ignore-existing myminio/loki-data
mc mb --ignore-existing myminio/loki-ruler
mc mb --ignore-existing myminio/loki-admin

# List all buckets to verify creation
echo 'Listing all buckets:'
mc ls myminio
"

# Clean up
echo "Cleaning up temporary pod..."
kubectl delete pod -n storage minio-client

echo "Buckets created successfully" 