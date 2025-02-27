# Supabase on Kubernetes

This directory contains the Kubernetes manifests for deploying Supabase on Kubernetes using Helm charts from the [supabase-kubernetes](https://github.com/supabase-community/supabase-kubernetes) project.

## Components

Supabase is an open-source Firebase alternative that provides:

- PostgreSQL Database
- Authentication and Authorization
- Auto-generated APIs
- Realtime subscriptions
- Storage
- Dashboard

## Configuration

The Supabase deployment is configured in the `base/helmrelease.yaml` file. The configuration includes:

- Resource limits and requests for each component
- Persistence configuration
- Ingress configuration

## Accessing Supabase

Once deployed, Supabase can be accessed at the configured ingress host (default: `supabase.example.com`).

## References

- [Supabase Kubernetes GitHub Repository](https://github.com/supabase-community/supabase-kubernetes)
- [Supabase Documentation](https://supabase.com/docs) 