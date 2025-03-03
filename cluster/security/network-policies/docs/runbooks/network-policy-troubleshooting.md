# Network Policy Troubleshooting Runbook

This runbook provides step-by-step guidance for troubleshooting network policy issues in the cluster.

## Common Issues and Solutions

### 1. High Rate of Dropped Packets

**Symptoms:**
- Alert: `NetworkPolicyDropsHigh`
- High number of dropped packets in specific pods
- Applications experiencing connection issues

**Investigation Steps:**
1. Check the affected pod's network policies:
   ```bash
   kubectl get networkpolicy -n <namespace> -o yaml
   ```

2. Verify pod labels match network policy selectors:
   ```bash
   kubectl get pod <pod-name> -n <namespace> --show-labels
   ```

3. Check pod logs for connection errors:
   ```bash
   kubectl logs <pod-name> -n <namespace>
   ```

4. Use the test client to verify connectivity:
   ```bash
   kubectl exec -it -n netpol-test netpol-test-client -- curl -v <service-name>
   ```

**Resolution:**
1. Review and update network policies if needed
2. Ensure pod labels match policy selectors
3. Add necessary ingress/egress rules
4. Test changes using the validation framework

### 2. Egress Blocking Issues

**Symptoms:**
- Alert: `NetworkPolicyEgressBlockedHigh`
- Applications unable to reach external services
- High number of TCP RST packets

**Investigation Steps:**
1. Check egress policies:
   ```bash
   kubectl get networkpolicy -n <namespace> -o yaml | grep -A 10 "policyTypes:"
   ```

2. Verify external service connectivity:
   ```bash
   kubectl exec -it -n netpol-test netpol-test-client -- curl -v <external-url>
   ```

3. Check DNS resolution:
   ```bash
   kubectl exec -it -n netpol-test netpol-test-client -- nslookup <service-name>
   ```

**Resolution:**
1. Add necessary egress rules
2. Verify DNS policies
3. Check for conflicting policies
4. Test changes using the validation framework

### 3. Ingress Blocking Issues

**Symptoms:**
- Alert: `NetworkPolicyIngressBlockedHigh`
- External access to services failing
- High number of TCP errors

**Investigation Steps:**
1. Check ingress policies:
   ```bash
   kubectl get networkpolicy -n <namespace> -o yaml | grep -A 10 "ingress:"
   ```

2. Verify ingress controller access:
   ```bash
   kubectl get pods -n infra -l app.kubernetes.io/name=ingress-nginx
   ```

3. Check service configuration:
   ```bash
   kubectl get service <service-name> -n <namespace> -o yaml
   ```

**Resolution:**
1. Review and update ingress rules
2. Verify ingress controller configuration
3. Check service selectors
4. Test changes using the validation framework

## Emergency Rollback Procedure

If critical services are affected:

1. Identify affected namespaces:
   ```bash
   kubectl get networkpolicy --all-namespaces
   ```

2. Roll back specific namespace:
   ```bash
   ./deploy-policies.sh rollback <namespace>
   ```

3. Or roll back all policies:
   ```bash
   ./deploy-policies.sh rollback-all
   ```

## Validation and Testing

After making changes:

1. Run validation tests:
   ```bash
   ./deploy-policies.sh verify
   ```

2. Check monitoring:
   - Review Prometheus metrics
   - Check Falco alerts
   - Monitor application logs

3. Verify service connectivity:
   ```bash
   kubectl exec -it -n netpol-test netpol-test-client -- curl -v <service-name>
   ```

## Best Practices

1. **Always Test First:**
   - Use the test namespace
   - Run validation jobs
   - Check monitoring

2. **Gradual Rollout:**
   - Deploy to non-critical namespaces first
   - Use phased deployment
   - Monitor for issues

3. **Documentation:**
   - Update network policies documentation
   - Record any issues and solutions
   - Maintain runbook with new findings

4. **Monitoring:**
   - Watch for alerts
   - Review metrics regularly
   - Check Falco events

## Support and Escalation

If issues persist:

1. Check the network policy documentation
2. Review recent changes to policies
3. Consult the security team
4. Escalate to cluster administrators 