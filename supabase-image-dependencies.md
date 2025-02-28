# Supabase Image Dependencies

This document outlines the specific Docker images and versions required for the Supabase deployment to function correctly. These specific versions were determined through testing and should be maintained to ensure stability.

## Critical Image Versions

| Component | Image | Version | Notes |
|-----------|-------|---------|-------|
| Database | supabase/postgres | 15.8.1.046 | Must use this exact version for compatibility with extensions |
| Auth | supabase/gotrue | v2.143.0 | Stable version with no initialization issues |
| Realtime | supabase/realtime | v2.25.4 | **Critical**: Newer versions have Elixir initialization issues |
| Meta | supabase/postgres-meta | v0.80.0 | Compatible with the database version |
| Analytics | supabase/logflare | 1.11.0 | Required for proper integration with other components |
| Vector | timberio/vector | 0.30.0-alpine | Newer versions might have compatibility issues |
| Functions | supabase/edge-runtime | v1.67.0 | Required for edge functions to work correctly |

## Components Using Latest Tag

The following components are currently using the `latest` tag, which works but may cause instability if the images are updated. Consider pinning these to specific versions in production:

| Component | Image | Current Tag | Recommendation |
|-----------|-------|-------------|----------------|
| Studio | supabase/studio | latest | Pin to a specific version |
| REST | postgrest/postgrest | latest | Pin to a specific version |
| Storage | supabase/storage-api | latest | Pin to a specific version |
| ImgProxy | darthsim/imgproxy | latest | Pin to a specific version |
| Kong | kong | latest | Pin to a specific version |

## Important Version Dependencies

- **Realtime**: Version v2.25.4 is specifically required as newer versions have Elixir initialization issues that prevent the service from starting correctly.
- **Database**: The 15.8.1.046 version includes necessary extensions and configurations for Supabase to function properly.
- **Vector**: The 0.30.0-alpine version is used instead of newer versions to maintain compatibility with the log handling system.

## Migration Recommendations

When upgrading components:

1. Always test in a non-production environment first
2. Upgrade one component at a time
3. Pay special attention to the Realtime component, which is sensitive to version changes
4. Consider pinning all `latest` tags to specific versions to prevent unexpected changes
5. Document all version changes carefully

This document should be updated whenever image versions are changed to maintain an accurate record of the deployment configuration. 