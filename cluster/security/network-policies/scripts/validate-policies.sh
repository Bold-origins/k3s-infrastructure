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

# Test connectivity between pods
test_connectivity() {
  local from_pod=$1
  local to_pod=$2
  local from_ns=$3
  local to_ns=$4
  local expected=$5

  log_info "Testing connectivity from $from_pod ($from_ns) to $to_pod ($to_ns)..."
  
  if kubectl exec -it -n $from_ns $from_pod --context kind-netpol-test -- curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://$to_pod.$to_ns.svc.cluster.local; then
    if [ "$expected" = "allow" ]; then
      log_info "✅ Connection allowed (expected)"
    else
      log_error "❌ Connection allowed (should be blocked)"
      return 1
    fi
  else
    if [ "$expected" = "deny" ]; then
      log_info "✅ Connection blocked (expected)"
    else
      log_error "❌ Connection blocked (should be allowed)"
      return 1
    fi
  fi
}

# Test external connectivity
test_external() {
  local pod=$1
  local ns=$2
  local expected=$3

  log_info "Testing external connectivity from $pod ($ns)..."
  
  if kubectl exec -it -n $ns $pod --context kind-netpol-test -- curl -s -o /dev/null -w "%{http_code}" --max-time 5 https://example.com; then
    if [ "$expected" = "allow" ]; then
      log_info "✅ External connection allowed (expected)"
    else
      log_error "❌ External connection allowed (should be blocked)"
      return 1
    fi
  else
    if [ "$expected" = "deny" ]; then
      log_info "✅ External connection blocked (expected)"
    else
      log_error "❌ External connection blocked (should be allowed)"
      return 1
    fi
  fi
}

# Test DNS resolution
test_dns() {
  local pod=$1
  local ns=$2
  local domain=$3
  local expected=$4

  log_info "Testing DNS resolution for $domain from $pod ($ns)..."
  
  if kubectl exec -it -n $ns $pod --context kind-netpol-test -- nslookup $domain; then
    if [ "$expected" = "allow" ]; then
      log_info "✅ DNS resolution allowed (expected)"
    else
      log_error "❌ DNS resolution allowed (should be blocked)"
      return 1
    fi
  else
    if [ "$expected" = "deny" ]; then
      log_info "✅ DNS resolution blocked (expected)"
    else
      log_error "❌ DNS resolution blocked (should be allowed)"
      return 1
    fi
  fi
}

# Check if Falco is running in either security or falco namespace
check_falco() {
  if kubectl get pods -n security -l app.kubernetes.io/name=falco --field-selector status.phase=Running --context kind-netpol-test | grep -q "falco"; then
    return 0
  fi
  if kubectl get pods -n falco -l app.kubernetes.io/name=falco --field-selector status.phase=Running --context kind-netpol-test | grep -q "falco"; then
    return 0
  fi
  return 1
}

# Main validation function
validate_policies() {
  local failed=0

  # Test default namespace isolation
  test_connectivity "netpol-test-client" "netpol-test-server" "netpol-test" "netpol-test" "allow" || failed=1
  test_connectivity "netpol-test-client" "netpol-test-server" "netpol-test" "default" "deny" || failed=1

  # Test infrastructure namespace
  test_connectivity "netpol-test-client" "ingress-nginx-controller" "netpol-test" "infra" "deny" || failed=1
  test_dns "netpol-test-client" "netpol-test" "kubernetes.default.svc.cluster.local" "allow" || failed=1

  # Test observability namespace
  test_connectivity "netpol-test-client" "prometheus-server" "netpol-test" "observability" "deny" || failed=1

  # Test external connectivity
  test_external "netpol-test-client" "netpol-test" "deny" || failed=1

  # Test monitoring
  log_info "Checking monitoring setup..."
  if ! kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus --field-selector status.phase=Running --context kind-netpol-test | grep -q "prometheus"; then
    log_error "❌ Prometheus is not running"
    failed=1
  fi

  if ! check_falco; then
    log_error "❌ Falco is not running"
    failed=1
  fi

  if [ $failed -eq 0 ]; then
    log_info "✅ All network policy tests passed!"
  else
    log_error "❌ Some network policy tests failed"
    exit 1
  fi
}

# Run validation
validate_policies 