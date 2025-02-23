# Certificate Issuance Problem Assessment
**Date**: February 23, 2025
**Environment**: Kubernetes with k3s
**Primary Issue**: SSL Certificate Acquisition Failure

## Executive Summary

The Kubernetes cluster is currently experiencing issues with automatic SSL certificate issuance through Let's Encrypt. The primary domain `test.boldorigins.io` is unable to obtain its SSL certificate due to HTTP-01 challenge verification failures.

## Infrastructure Components

### 1. Load Balancer (MetalLB)
```yaml
# cluster/core/metallb/config/ipaddresspool.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default
  namespace: infra
spec:
  addresses:
    - 147.93.89.100-147.93.89.120  # Current IP range
```

### 2. Ingress Controller (nginx)
```yaml
# cluster/core/ingress/helmrelease.yaml
apiVersion: helm.toolkit.fluxcd.io/v2beta2
kind: HelmRelease
metadata:
  name: ingress-nginx
  namespace: infra
spec:
  values:
    controller:
      service:
        enabled: true
        externalTrafficPolicy: Local
        type: LoadBalancer
      extraArgs:
        enable-ssl-passthrough: true
```

### 3. Test Ingress Resource
```yaml
# cluster/core/ingress/test-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-ingress
  namespace: infra
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "false"
```

## Current Status

### Working Components ✅

1. **DNS Resolution**
   - Domain `test.boldorigins.io` correctly resolves to `147.93.89.100`
   - DNS propagation is complete and functioning

2. **Internal Kubernetes Services**
   - All pods are running and healthy
   - Internal service communication is functional
   - cert-manager is operational and creating resources

### Problematic Components ⚠️

1. **External Access**
   - Connection resets occurring on port 80
   - Let's Encrypt unable to validate HTTP-01 challenges
   - External requests failing with timeout errors

2. **Certificate Issuance**
   - HTTP-01 challenges consistently failing
   - cert-manager reporting connection timeouts
   - Challenge solver pods created but not externally accessible

## Error Analysis

### Key Error Messages

1. **cert-manager Logs**
```
acme: authorization error for test.boldorigins.io: 400 urn:ietf:params:acme:error:connection: 
147.93.89.100: Fetching http://test.boldorigins.io/.well-known/acme-challenge/: 
Timeout during connect (likely firewall problem)
```

2. **Ingress Controller Logs**
```
10.42.0.120 - - [23/Feb/2025:19:42:34 +0000] "GET /.well-known/acme-challenge/[...] HTTP/1.1" 200 87
```

### Diagnostic Findings

1. **Internal vs External Access**
   - Internal requests succeed (200 OK responses)
   - External requests fail (connection resets)
   - Suggests network/firewall issue

2. **Service Configuration**
   - LoadBalancer service properly configured
   - IP assignment working correctly
   - Traffic policy may need adjustment

## Root Cause Analysis

### Primary Issues Identified

1. **Network Access**
   - External traffic being blocked or reset
   - Possible firewall rules interfering
   - Potential network policy restrictions

2. **Configuration Concerns**
   - `externalTrafficPolicy: Local` may be affecting routing
   - Possible MetalLB advertisement issues
   - Ingress controller configuration may need adjustment

## Recommendations

### Immediate Actions

1. **Firewall Verification**
   ```bash
   sudo ufw status
   sudo iptables -L
   ```

2. **Network Policy Review**
   ```bash
   kubectl get networkpolicies -A
   ```

3. **Service Configuration Update**
   - Test with `externalTrafficPolicy: Cluster`
   - Verify MetalLB L2 advertisement

### Long-term Solutions

1. **Monitoring Improvements**
   - Add detailed network monitoring
   - Implement better logging for external access

2. **Infrastructure Updates**
   - Review and update firewall rules
   - Document network requirements
   - Implement proper network policies

## Testing Procedure

1. **External Access Test**
```bash
curl -v http://test.boldorigins.io/.well-known/acme-challenge/test
```

2. **Internal Access Test**
```bash
kubectl run -n infra curl --image=curlimages/curl --rm -it --restart=Never -- \
  curl -v http://test.boldorigins.io/.well-known/acme-challenge/test
```

3. **Service Verification**
```bash
kubectl get svc -n infra ingress-nginx-controller -o yaml
```

## Contact Information

For further assistance or questions about this assessment, please contact the infrastructure team.

---
*Note: This assessment is based on the current state of the system as of February 23, 2025. Conditions may have changed since this documentation was prepared.* 