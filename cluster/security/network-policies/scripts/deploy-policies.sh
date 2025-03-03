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

# Check if running in production
is_production() {
  [ "$KUBERNETES_ENV" = "production" ]
}

# Deploy policies for a specific namespace
deploy_namespace() {
  local namespace=$1
  log_info "Deploying network policies for namespace: $namespace"
  
  # Apply namespace policies
  kubectl apply -k "policies/$namespace"
  
  # Wait for policies to be ready
  kubectl wait --for=condition=ready networkpolicy -n $namespace --all --timeout=60s
  
  # Run validation tests
  ./scripts/validate-policies.sh
  
  log_info "✅ Network policies deployed for $namespace"
}

# Rollback policies for a specific namespace
rollback_namespace() {
  local namespace=$1
  log_info "Rolling back network policies for namespace: $namespace"
  
  # Delete namespace policies
  kubectl delete -k "policies/$namespace" --ignore-not-found
  
  log_info "✅ Network policies rolled back for $namespace"
}

# Deploy all policies
deploy_all() {
  log_warn "⚠️  Deploying all network policies at once. This is not recommended for production."
  
  # Deploy monitoring first
  kubectl apply -k monitoring/
  
  # Deploy namespace policies
  for ns in infra observability security storage supabase; do
    deploy_namespace $ns
  done
  
  # Deploy default policies last
  deploy_namespace default
  
  log_info "✅ All network policies deployed"
}

# Phased deployment
deploy_phased() {
  log_info "Starting phased deployment of network policies..."
  
  # Phase 1: Deploy monitoring
  log_info "Phase 1: Deploying monitoring..."
  kubectl apply -k monitoring/
  
  # Phase 2: Deploy non-critical namespaces
  log_info "Phase 2: Deploying non-critical namespaces..."
  for ns in observability security; do
    deploy_namespace $ns
    read -p "Press Enter to continue to next namespace..."
  done
  
  # Phase 3: Deploy infrastructure
  log_info "Phase 3: Deploying infrastructure namespace..."
  deploy_namespace infra
  read -p "Press Enter to continue..."
  
  # Phase 4: Deploy storage and supabase
  log_info "Phase 4: Deploying storage and supabase namespaces..."
  for ns in storage supabase; do
    deploy_namespace $ns
    read -p "Press Enter to continue to next namespace..."
  done
  
  # Phase 5: Deploy default policies
  log_info "Phase 5: Deploying default policies..."
  if is_production; then
    read -p "⚠️  Are you sure you want to deploy default policies in production? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      log_warn "Default policies deployment skipped"
      return
    fi
  fi
  deploy_namespace default
  
  log_info "✅ Phased deployment completed"
}

# Rollback all policies
rollback_all() {
  log_warn "⚠️  Rolling back all network policies..."
  
  # Rollback in reverse order
  rollback_namespace default
  
  for ns in supabase storage infra security observability; do
    rollback_namespace $ns
  done
  
  # Rollback monitoring last
  kubectl delete -k monitoring/ --ignore-not-found
  
  log_info "✅ All network policies rolled back"
}

# Main script
case "$1" in
  "deploy-all")
    deploy_all
    ;;
  "deploy-phased")
    deploy_phased
    ;;
  "deploy-single")
    if [ -z "$2" ]; then
      log_error "Namespace not specified"
      exit 1
    fi
    deploy_namespace "$2"
    ;;
  "rollback")
    if [ -z "$2" ]; then
      log_error "Namespace not specified"
      exit 1
    fi
    rollback_namespace "$2"
    ;;
  "rollback-all")
    rollback_all
    ;;
  "verify")
    ./scripts/validate-policies.sh
    ;;
  *)
    echo "Usage: $0 {deploy-all|deploy-phased|deploy-single <namespace>|rollback <namespace>|rollback-all|verify}"
    exit 1
    ;;
esac 