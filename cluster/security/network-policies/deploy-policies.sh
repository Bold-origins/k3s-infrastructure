#!/bin/bash
# Network Policy Phased Deployment Script
# Implements a GitOps-friendly, phased rollout of network policies

set -e

# Base directory for network policies
BASE_DIR="$(dirname "$0")"
cd "$BASE_DIR"

# Define color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

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

# Function to check if the test namespace exists
check_test_namespace() {
  log_info "Checking if test namespace exists..."
  if kubectl get namespace netpol-test > /dev/null 2>&1; then
    log_info "Test namespace exists."
    return 0
  else
    log_info "Test namespace doesn't exist. Creating it along with test pods..."
    kubectl apply -k testing/validation-pods/
    sleep 5
    log_info "Waiting for test pods to be ready..."
    kubectl wait --for=condition=ready pod -l app=netpol-test-client -n netpol-test --timeout=60s
    kubectl wait --for=condition=ready pod -l app=netpol-test-server -n netpol-test --timeout=60s
    return 0
  fi
}

# Function to deploy a namespace's policies
deploy_namespace_policies() {
  namespace=$1
  log_info "Deploying network policies for namespace: $namespace"
  kubectl apply -k policies/$namespace/
  log_info "Network policies for $namespace namespace applied successfully."
  sleep 2
}

# Function to verify network policies
verify_policies() {
  log_info "Running network policy verification..."
  kubectl apply -k testing/validation-jobs/
  sleep 5
  
  # Wait for job to complete
  kubectl wait --for=condition=complete job/netpol-connectivity-test -n netpol-test --timeout=60s
  
  # Get logs
  log_info "Test results:"
  echo "---------------------------------------------------"
  kubectl logs job/netpol-connectivity-test -n netpol-test
  echo "---------------------------------------------------"
  
  # Clean up job
  kubectl delete job netpol-connectivity-test -n netpol-test
}

# Function to implement a rollback
rollback() {
  log_warn "Rolling back network policies..."
  kubectl delete networkpolicy --all -n $1
  log_info "Rollback complete for namespace $1."
}

# Main execution

case "$1" in
  "test-setup")
    check_test_namespace
    log_info "Test environment is ready."
    ;;
  
  "deploy-all")
    log_info "Deploying all network policies at once - BE CAREFUL!"
    check_test_namespace
    for ns in default infra observability storage security supabase; do
      deploy_namespace_policies $ns
    done
    verify_policies
    ;;
  
  "deploy-phased")
    log_info "Starting phased deployment of network policies..."
    check_test_namespace
    
    # First apply specific namespace policies without default-deny
    for ns in storage security observability supabase infra; do
      deploy_namespace_policies $ns
      log_info "Waiting 10 seconds to observe any issues..."
      sleep 10
      log_info "Phase for $ns completed successfully."
    done
    
    log_info "All namespace-specific policies have been applied."
    
    # Now apply default deny policies
    log_warn "About to apply default-deny policies. This will restrict all unspecified traffic."
    read -p "Are you sure you want to continue? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      deploy_namespace_policies default
      log_info "Default deny policies applied."
    else
      log_info "Skipping default deny policies."
    fi
    
    verify_policies
    ;;
  
  "deploy-single")
    if [ -z "$2" ]; then
      log_error "Please specify a namespace: $0 deploy-single [namespace]"
      exit 1
    fi
    
    check_test_namespace
    deploy_namespace_policies $2
    verify_policies
    ;;
  
  "rollback")
    if [ -z "$2" ]; then
      log_error "Please specify a namespace to rollback: $0 rollback [namespace]"
      exit 1
    fi
    
    rollback $2
    ;;
  
  "rollback-all")
    log_warn "Rolling back ALL network policies!"
    read -p "Are you sure you want to continue? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      for ns in infra observability storage security supabase; do
        rollback $ns
      done
      log_info "All network policies rolled back."
    else
      log_info "Rollback cancelled."
    fi
    ;;
  
  "verify")
    check_test_namespace
    verify_policies
    ;;
  
  *)
    echo "Network Policy Deployment Tool"
    echo "------------------------------"
    echo "Usage: $0 [command]"
    echo
    echo "Commands:"
    echo "  test-setup          Setup the test environment"
    echo "  deploy-all          Deploy all network policies at once"
    echo "  deploy-phased       Deploy network policies in phases (recommended)"
    echo "  deploy-single [ns]  Deploy network policies for a single namespace"
    echo "  rollback [ns]       Rollback network policies for a namespace"
    echo "  rollback-all        Rollback all network policies"
    echo "  verify              Verify network policies are working correctly"
    echo
    ;;
esac

exit 0 