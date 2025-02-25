# k3s-infrastructure

This repository contains the GitOps infrastructure configuration for a k3s Kubernetes cluster. The infrastructure is managed using Flux CD and includes comprehensive security monitoring, observability, and core infrastructure components.

## 🏗️ Infrastructure Components

### Core Infrastructure

- **Ingress-Nginx**: Kubernetes ingress controller
- **Cert-Manager**: Automatic TLS certificate management
- **Sealed Secrets**: Secure secret management in Git

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

## 🚀 Getting Started

### Prerequisites

- k3s cluster
- `kubectl` CLI tool
- `flux` CLI tool
- `helm` CLI tool (optional)

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

### Accessing Services

#### Grafana

```bash
kubectl -n observability port-forward svc/kube-prometheus-stack-grafana 3000:80
```

- URL: <http://localhost:3000>
- Default credentials:
  - Username: admin
  - Password: supersecret123

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
├── security/           # Security-related components
├── observability/      # Monitoring and logging
├── storage/           # Storage solutions
└── flux-system/       # Flux configuration
```

## 🛠️ Maintenance

### Checking Component Status

```bash
# View all Helm releases
kubectl get helmreleases -A

# Check Flux status
flux get all
```

### Common Tasks

#### Updating Components

Components are automatically updated based on the version constraints in their HelmRelease definitions.

#### Sealed Secrets

To create a new sealed secret:

```bash
kubeseal -f secret.yaml -w sealed-secret.yaml
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
