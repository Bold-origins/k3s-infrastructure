# Supabase Fixes Summary

This document catalogs the manual fixes that were successfully applied to make Supabase work properly.

## Database User and Schema Fixes

1. **Created necessary users with proper permissions**
   - Created supabase_admin, supabase_auth_admin, supabase_storage_admin, supabase_realtime_admin
   - Set up appropriate permissions for each role

2. **Created and configured required schemas**
   - Set up the realtime schema
   - Created the logflare schema 
   - Moved system metrics tables to the logflare schema
   - Configured proper schema ownership and permissions

## Image and Configuration Fixes

1. **Fixed Realtime Pod**
   - Changed image from v2.25.8 to v2.25.4 to resolve Elixir initialization issues
   - Updated configuration to use proper search paths

2. **Fixed Analytics Pod**
   - Created required tables in logflare schema (users, sources)
   - Added sample data to prevent initialization errors
   - Set up proper schema search paths

## Ingress Configuration

1. **Configured proper ingress**
   - Set up host as supabase.boldorigins.io
   - Added TLS configuration with Let's Encrypt
   - Added appropriate annotations for the nginx ingress controller

## SQL Scripts That Worked

The following SQL scripts were effective:

1. `create_supabase_users.sql` - Created the necessary database roles
2. `create_realtime_schema.sql` - Set up the realtime schema and tables
3. `create_realtime_role.sql` - Created the realtime role with proper permissions
4. `create_analytics_schema.sql` - Created the _analytics schema
5. `create_analytics_tables.sql` - Created system_metrics table
6. `analytics_fix.sql` - Created users and sources tables for analytics
7. `additional_permissions.sql` - Set up proper permissions between schemas
8. `fix_ownership.sql` - Fixed schema ownership issues 