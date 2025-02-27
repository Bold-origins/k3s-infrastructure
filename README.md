# k3s-infrastructure

This repository contains the GitOps infrastructure configuration for a k3s Kubernetes cluster. The infrastructure is managed using Flux CD and includes comprehensive security monitoring, observability, and core infrastructure components.

## 🏗️ Infrastructure Components

### Core Infrastructure

- **Ingress-Nginx**: Kubernetes ingress controller
- **Cert-Manager**: Automatic TLS certificate management
- **Sealed Secrets**: Secure secret management in Git
- **MetalLB**: Layer 2 load balancer for bare metal Kubernetes clusters

### Security

- **Falco**: Runtime security monitoring and threat detection
- **Vault**: Secrets management and encryption
- **Gatekeeper**: Policy enforcement and governance

### Observability

- **Prometheus** (via kube-prometheus-stack): Metrics collection and storage
- **Grafana**: Metrics visualization and dashboards
- **Loki**: Log aggregation
- **Tempo**: Distributed tracing

### Storage

- **MinIO**: S3-compatible object storage

### Application Platform

- **Supabase**: Open-source Firebase alternative with PostgreSQL, Auth, Storage, and more

## 🚀 Getting Started

### Prerequisites

- k3s cluster
- `kubectl` CLI tool
- `flux` CLI tool
- `helm` CLI tool (optional)
- `kubeseal` CLI tool (for secret management)
- `jq` command-line JSON processor (for some scripts)

### Initial Setup

1. Clone this repository:

```bash
git clone https://github.com/yourusername/k3s-infrastructure.git
cd k3s-infrastructure
```

2. Bootstrap Flux:

```bash
flux bootstrap github \
  --owner=yourusername \
  --repository=k3s-infrastructure \
  --branch=main \
  --path=cluster
```

3. Set up secret management:

```bash
# Copy the example credentials file
cp scripts/ui-credentials.txt.example scripts/ui-credentials.txt

# Edit the credentials file with your actual values
vim scripts/ui-credentials.txt

# Set required environment variables
export VAULT_TOKEN='your-vault-token'

# Store credentials
./scripts/store-ui-credentials.sh
```

### Accessing Services

#### Grafana

```bash
kubectl -n observability port-forward svc/kube-prometheus-stack-grafana 3000:80
```

- URL: <http://localhost:3000>
- Default credentials:
  - Username: admin
  - Password: See scripts/ui-credentials.txt

#### MinIO Console

```bash
kubectl -n storage port-forward svc/minio-console 9001:9001
```

- URL: <http://localhost:9001>
- Default credentials: See scripts/ui-credentials.txt

#### Supabase Studio

```bash
kubectl -n supabase port-forward svc/supabase-studio 3001:3000
```

- URL: <http://localhost:3001>
- Default credentials: Set during installation

#### Tempo (Tracing)

```bash
kubectl -n observability port-forward svc/tempo 3200:3200
kubectl -n observability port-forward svc/tempo 4317:4317 4318:4318
```

## 🔒 Security Monitoring with Falco

### Overview

Falco provides runtime security monitoring for your Kubernetes cluster. It monitors:

- System calls
- Container activities
- Kubernetes events
- Network connections

### Viewing Security Events

1. Access the Falco dashboard in Grafana
2. Navigate to "Dashboards" -> "Security" -> "Falco Security Events"

### Monitoring Features

- Real-time security event monitoring
- Event rate tracking
- Total event count visualization
- JSON-formatted logs for better parsing

## 📊 Observability Stack

### Components

#### Prometheus

- Metrics collection and storage
- Service discovery for automatic monitoring
- Long-term metrics retention

#### Grafana

- Metric visualization
- Pre-configured dashboards
- Alert management

#### Loki

- Log aggregation
- Log querying and visualization
- Integration with Grafana

#### Tempo

- Distributed tracing
- Request flow visualization
- Performance monitoring

## 🔄 GitOps Workflow

This infrastructure follows GitOps principles using Flux CD:

1. All changes should be made through Git
2. Flux automatically synchronizes the cluster state
3. Infrastructure is defined as code
4. Changes are declarative and version controlled

### Directory Structure

```bash
cluster/
├── core/               # Core infrastructure components
│   ├── cert-manager/   # Certificate management
│   ├── ingress/        # Ingress controller
│   ├── metallb/        # Load balancer for bare metal
│   ├── namespaces/     # Namespace definitions
│   ├── repositories/   # Helm repositories
│   └── secrets/        # Sealed secrets
├── security/           # Security-related components
│   ├── falco/          # Runtime security monitoring
│   ├── gatekeeper/     # Policy enforcement
│   └── vault/          # Secrets management
├── observability/      # Monitoring and logging
│   ├── kube-prometheus-stack/ # Prometheus and Grafana
│   ├── loki/           # Log aggregation
│   └── tempo/          # Distributed tracing
├── storage/            # Storage solutions
│   └── minio/          # S3-compatible object storage
├── supabase/           # Supabase platform
│   └── base/           # Base Supabase configuration
└── flux-system/        # Flux configuration
```

## 🛠️ Maintenance

### Checking Component Status

```bash
# View all Helm releases
kubectl get helmreleases -A

# Check Flux status
flux get all
```

### Secret Management

The repository includes several scripts in the `scripts/` directory to help manage secrets:

- `seal-secret.sh`: Seals a single key-value secret
- `seal-multi-secret.sh`: Seals multiple key-value pairs from a file
- `get-secret.sh`: Retrieves and decodes Kubernetes secrets
- `list-secrets.sh`: Lists all secrets with detailed information
- `list-namespaces.sh`: Lists all namespaces with their purposes
- `store-ui-credentials.sh`: Stores UI credentials in both Sealed Secrets and Vault

For more details, see the [Secret Management Scripts README](scripts/README.md).

### Common Tasks

#### Updating Components

Components are automatically updated based on the version constraints in their HelmRelease definitions.

#### Sealed Secrets

To create a new sealed secret:

```bash
# Create a single key-value secret
./scripts/seal-secret.sh -n my-namespace -s my-secret -k username -v admin

# Create a multi-key secret from a file
./scripts/seal-multi-secret.sh -n my-namespace -s my-secret -f values.txt
```

## 🚨 Troubleshooting

### Common Issues

1. **Flux Sync Issues**

```bash
flux reconcile source git flux-system
```

2. **Pod Status Check**

```bash
kubectl get pods -A | grep -i error
```

3. **Logs Access**

```bash
# Falco logs
kubectl logs -n security -l app=falco

# Prometheus logs
kubectl logs -n observability -l app=prometheus
```

## 📝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Support

For support, please open an issue in the repository or contact the maintainers.