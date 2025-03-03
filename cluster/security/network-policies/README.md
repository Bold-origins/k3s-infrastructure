# Network Policies Framework

This directory contains the network policies, testing infrastructure, and deployment automation for the Kubernetes cluster network security.

## Structure

```
network-policies/
├── deploy-policies.sh         # Deployment automation script
├── policies/                  # Network policies per namespace
│   ├── default/               # Default (global) network policies
│   ├── infra/                 # Infrastructure namespace policies
│   ├── observability/         # Observability namespace policies
│   ├── security/              # Security namespace policies
│   ├── storage/               # Storage namespace policies
│   └── supabase/              # Supabase namespace policies
├── testing/                   # Test infrastructure
│   ├── validation-jobs/       # Automated test jobs
│   └── validation-pods/       # Test pods for connectivity verification
├── monitoring/                # Monitoring and alerting
│   ├── netpol-alerts.yaml     # Prometheus alert rules
│   └── netpol-falco-rules.yaml # Falco rules for network policy violations
└── docs/                      # Documentation
    └── runbooks/             # Troubleshooting guides
```

## Design Philosophy

The network policies in this framework follow these principles:

1. **Default Deny, Explicit Allow**: We start with denying all traffic and selectively allow only necessary communication.
2. **Namespace Isolation**: Policies are organized by namespace for clearer management and isolation.
3. **Testable**: All policies can be validated through automated testing.
4. **GitOps-Friendly**: All policies are defined declaratively and can be managed through Git.
5. **Phased Deployment**: Policies can be rolled out gradually to minimize disruption.
6. **Observable**: Comprehensive monitoring and alerting for policy violations.

## Getting Started

### Prerequisites

- kubectl with access to the cluster
- kustomize (included with recent kubectl versions)

### Testing Environment

The testing environment consists of:

1. A dedicated `netpol-test` namespace
2. Test client pod with network tools
3. Test server pod running an nginx instance
4. Automated test jobs that validate connectivity

To set up the testing environment:

```bash
./deploy-policies.sh test-setup
```

### Deploying Policies

There are multiple deployment strategies available:

#### Phased Deployment (Recommended)

This approach applies policies in phases, with pauses to verify functionality:

```bash
./deploy-policies.sh deploy-phased
```

The phased deployment:
1. Applies specific namespace policies first
2. Waits to verify each phase works correctly
3. Finally applies default deny policies with confirmation prompt

#### Single Namespace Deployment

To deploy policies for a specific namespace:

```bash
./deploy-policies.sh deploy-single [namespace]
```

Replace `[namespace]` with one of: `default`, `infra`, `observability`, `security`, `storage`, or `supabase`.

#### Deploy All Policies at Once

⚠️ **Use with caution!** This applies all policies in one go:

```bash
./deploy-policies.sh deploy-all
```

### Validation

To verify policies are working correctly:

```bash
./deploy-policies.sh verify
```

This will:
1. Run a test job in the `netpol-test` namespace
2. Test internal connectivity (should work)
3. Test connectivity to protected services (should be blocked)
4. Display test results

### Rollback

If you need to roll back policies for a specific namespace:

```bash
./deploy-policies.sh rollback [namespace]
```

To roll back all network policies:

```bash
./deploy-policies.sh rollback-all
```

## Monitoring and Alerting

The framework includes comprehensive monitoring and alerting:

### Prometheus Alerts

The following alerts are configured:

1. **NetworkPolicyDropsHigh**
   - Triggered when a pod has a high rate of dropped packets
   - Indicates potential network policy blocking

2. **NetworkPolicyEgressBlockedHigh**
   - Triggered by high TCP RST packets
   - Suggests egress blocking issues

3. **NetworkPolicyIngressBlockedHigh**
   - Triggered by high TCP errors
   - Indicates ingress blocking problems

### Falco Rules

Custom Falco rules detect:

1. **Unexpected Ingress Traffic Denied**
   - Monitors for denied ingress connections
   - Excludes test pods and system namespaces

2. **Unexpected Egress Traffic Denied**
   - Tracks denied egress connections
   - Helps identify policy violations

3. **Network Policy Scanning Attempt**
   - Detects potential network scanning
   - Monitors connection patterns

## Troubleshooting

For detailed troubleshooting guidance, see the [Network Policy Troubleshooting Runbook](docs/runbooks/network-policy-troubleshooting.md).

Common issues and solutions:

1. **High Rate of Dropped Packets**
   - Check network policies
   - Verify pod labels
   - Review application logs

2. **Egress Blocking Issues**
   - Review egress policies
   - Check DNS resolution
   - Verify external connectivity

3. **Ingress Blocking Issues**
   - Check ingress rules
   - Verify ingress controller
   - Review service configuration

## Policy Overview

### Default Namespace
- Contains global default-deny policies
- Applied last in phased deployment

### Namespace-Specific Policies
Each namespace folder contains policies specific to that namespace, following a consistent pattern:
- Intra-namespace communication rules
- Inter-namespace communication rules
- External access rules

## Recommended Workflow

1. Set up the testing environment: `./deploy-policies.sh test-setup`
2. Deploy policies to non-critical namespaces first using single deployments
3. Validate each deployment: `./deploy-policies.sh verify`
4. When confident, run phased deployment: `./deploy-policies.sh deploy-phased`
5. Monitor for issues and be ready to roll back if needed

## CI/CD Integration

The framework includes GitHub Actions workflows that:

1. Validate network policy changes
2. Test policies in a Kind cluster
3. Run connectivity tests
4. Ensure policies follow best practices

See `.github/workflows/validate-network-policies.yaml` for details.

## Support and Maintenance

For issues or questions:

1. Check the troubleshooting runbook
2. Review monitoring alerts
3. Consult the security team
4. Escalate to cluster administrators 