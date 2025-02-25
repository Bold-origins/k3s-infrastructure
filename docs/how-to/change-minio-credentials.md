# How to Change MinIO Credentials

This guide explains how to safely change MinIO credentials in our k3s infrastructure.

## Prerequisites

- Access to the Kubernetes cluster
- `kubectl` command-line tool
- `kubeseal` command-line tool
- Git access to the infrastructure repository

## Steps

1. **Generate New Credentials**

   Choose your new credentials. For example:

   ```bash
   NEW_USER="your-new-username"
   NEW_PASS="your-new-secure-password"
   ```

2. **Create New SealedSecrets**

   Create both the admin and UI credentials SealedSecrets:

   ```bash
   # Create MinIO admin credentials SealedSecret
   kubectl create secret generic minio-credentials \
     --from-literal=root-user=$NEW_USER \
     --from-literal=root-password=$NEW_PASS \
     -n storage --dry-run=client -o yaml | \
   kubeseal --controller-namespace infra --controller-name sealed-secrets \
     --format yaml > cluster/storage/minio/secret.yaml

   # Create UI credentials SealedSecret
   kubectl create secret generic ui-minio-creds \
     --from-literal=minio_username=$NEW_USER \
     --from-literal=minio_password=$NEW_PASS \
     -n storage --dry-run=client -o yaml | \
   kubeseal --controller-namespace infra --controller-name sealed-secrets \
     --format yaml > cluster/storage/secrets/sealed-ui-credentials.yaml
   ```

3. **Commit and Push Changes**

   ```bash
   git add cluster/storage/minio/secret.yaml cluster/storage/secrets/sealed-ui-credentials.yaml
   git commit -m "feat: update MinIO credentials"
   git push
   ```

4. **Apply Changes**

   ```bash
   flux reconcile kustomization infrastructure-storage --with-source
   ```

5. **Verify Changes**

   Wait for the MinIO pod to restart and verify:

   ```bash
   # Watch for pod restart
   kubectl get pods -n storage -l app=minio -w
   
   # Once the pod is ready, verify you can log in with new credentials
   ```

## Important Notes

1. **Backup**: Before changing credentials, ensure you have backups of your MinIO data
2. **Downtime**: This process will cause a brief downtime as the MinIO pod restarts
3. **Applications**: Update any applications that use MinIO with the new credentials
4. **Testing**: Test the new credentials before logging out of your current session

## Troubleshooting

If you encounter issues:

1. Check the MinIO pod logs:

   ```bash
   kubectl logs -n storage -l app=minio
   ```

2. Verify the secrets were properly created:

   ```bash
   kubectl get secrets -n storage
   ```

3. Check the MinIO pod environment variables:

   ```bash
   kubectl exec -n storage $(kubectl get pods -n storage -l app=minio -o name) -- env | grep -i minio
   ```

## Security Considerations

- Store the new credentials securely
- Update any backup of infrastructure code
- Consider rotating credentials regularly as part of security practice
- Update any CI/CD systems that might be using these credentials
