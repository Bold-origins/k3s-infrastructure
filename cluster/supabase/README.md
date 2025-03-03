# Supabase Kubernetes Setup

This directory contains the Kubernetes manifests for deploying Supabase on a Kubernetes cluster.

## Prerequisites

- Kubernetes cluster
- Helm v3
- kubectl
- A default StorageClass for persistent volumes
- Ingress controller (nginx-ingress)
- cert-manager for TLS certificates

## Components

The deployment consists of the following components:

1. PostgreSQL Database
2. GoTrue (Auth)
3. PostgREST (REST API)
4. Realtime
5. Storage API
6. Studio (Dashboard)
7. Kong (API Gateway)
8. Analytics
9. Vector (Logging)
10. Functions

## Installation

1. First, create the namespace:
   ```bash
   kubectl create namespace supabase
   ```

2. Apply the database initialization ConfigMap and Job:
   ```bash
   kubectl apply -f initjobs/db-init-configmap.yaml
   kubectl apply -f initjobs/db-init-job.yaml
   ```
   This will:
   - Create necessary schemas (auth, realtime, storage, etc.)
   - Set up required database roles and permissions
   - Configure search paths for each service
   - Create required tables for migrations

3. Install Supabase using Helm:
   ```bash
   helm upgrade --install supabase . -n supabase
   ```

## Required Secrets

The following secrets must be present in the cluster:

1. `supabase-jwt`: JWT configuration
   - `anonKey`: Anonymous API key
   - `serviceKey`: Service role API key
   - `secret`: JWT secret key

2. `supabase-smtp`: Email service credentials
   - `username`: SMTP username
   - `password`: SMTP password

3. `supabase-dashboard`: Studio dashboard credentials
   - `username`: Dashboard username
   - `password`: Dashboard password

4. `supabase-db`: Database credentials
   - `username`: Database username
   - `password`: Database password
   - `database`: Database name

5. `supabase-analytics`: Analytics configuration
   - `apiKey`: Analytics API key

6. `supabase-s3`: Storage configuration (if using S3)
   - `keyId`: S3 access key ID
   - `accessKey`: S3 secret access key

## Environment Variables

Key environment variables are configured in `values.yaml`. Important settings include:

- Database connection details
- Service URLs and endpoints
- Email configuration
- Storage backend configuration

## Troubleshooting

Common issues and their solutions:

1. Database Initialization Issues
   - Check the init job logs: `kubectl logs -n supabase jobs/supabase-db-init`
   - Verify the ConfigMap is properly mounted
   - Ensure database is accessible

2. Service Startup Issues
   - Check service logs: `kubectl logs -n supabase deployment/supabase-supabase-[service]`
   - Verify secrets are properly mounted
   - Check environment variables are correctly set

3. Permission Issues
   - Verify database roles and permissions are correctly set
   - Check service account permissions
   - Ensure proper schema ownership

## Maintenance

1. Updating Secrets
   ```bash
   kubectl create secret generic [secret-name] --namespace supabase \
     --from-literal=key=value \
     --dry-run=client -o yaml | kubectl apply -f -
   ```

2. Restarting Services
   ```bash
   kubectl rollout restart deployment -n supabase [deployment-name]
   ```

3. Checking Logs
   ```bash
   kubectl logs -n supabase -l app.kubernetes.io/name=[service-name]
   ```

## Security Considerations

1. All secrets are managed through Kubernetes secrets
2. Database users have minimal required permissions
3. Services run with non-root users
4. Network policies should be configured to restrict inter-service communication
5. TLS is enabled for external access

## Backup and Recovery

1. Database backups should be configured through PostgreSQL backup solutions
2. Persistent volumes should be backed up according to your storage provider's recommendations
3. Secrets should be backed up securely

## Monitoring

Consider setting up:
1. PostgreSQL monitoring
2. Service metrics collection
3. Log aggregation
4. Alert rules for critical services 