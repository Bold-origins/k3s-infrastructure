#!/bin/bash

# Exit on error
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Helper functions
log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Kind is installed
if ! command -v kind &> /dev/null; then
  log_error "Kind is not installed. Please install it first."
  exit 1
fi

# Create Kind cluster if it doesn't exist
if ! kind get clusters | grep -q "netpol-test"; then
  log_info "Creating Kind cluster 'netpol-test'..."
  kind create cluster --name netpol-test --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraMounts:
  - hostPath: /var/run/docker.sock
    containerPath: /var/run/docker.sock
  - hostPath: /var/lib/docker
    containerPath: /var/lib/docker
networking:
  disableDefaultCNI: true
  podSubnet: "10.244.0.0/16"
EOF
fi

# Install Calico CNI
log_info "Installing Calico CNI..."
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml
kubectl -n kube-system wait --for=condition=ready pod -l k8s-app=calico-node --timeout=90s

# Create test namespaces
log_info "Creating test namespaces..."
kubectl create namespace netpol-test --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace infra --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace observability --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace security --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace storage --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace supabase --dry-run=client -o yaml | kubectl apply -f -

# Apply test environment
log_info "Setting up test environment..."
cd "$(dirname "$0")/.."
kubectl apply -f testing/validation-pods/test-pods.yaml

# Wait for test pods to be ready
log_info "Waiting for test pods to be ready..."
kubectl wait --for=condition=ready pod -l app=netpol-test-client -n netpol-test --timeout=60s
kubectl wait --for=condition=ready pod -l app=netpol-test-server -n netpol-test --timeout=60s

# Apply monitoring stack
log_info "Setting up monitoring stack..."
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring

# Wait for monitoring stack to be ready
log_info "Waiting for monitoring stack to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n monitoring --timeout=120s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n monitoring --timeout=120s

# Apply Falco
log_info "Setting up Falco..."
kubectl create namespace falco --dry-run=client -o yaml | kubectl apply -f -
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update
helm install falco falcosecurity/falco --namespace falco --set falco.jsonOutput=true

# Wait for Falco to be ready
log_info "Waiting for Falco to be ready..."
kubectl wait --for=condition=ready pod -l app=falco -n falco --timeout=120s

log_info "Test environment is ready!"
log_info "You can now run: ./deploy-policies.sh test-setup" 