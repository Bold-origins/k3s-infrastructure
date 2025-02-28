-- Additional permissions for Supabase services

-- Create extensions if they don't exist (commonly used by Supabase)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create schemas that Supabase services expect
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS storage;
CREATE SCHEMA IF NOT EXISTS realtime;

-- Grant permissions on schemas
GRANT ALL ON SCHEMA auth TO supabase_auth_admin;
GRANT ALL ON SCHEMA storage TO supabase_storage_admin;
GRANT ALL ON SCHEMA realtime TO postgres;
GRANT USAGE ON SCHEMA public TO authenticator;

-- Grant permissions for supabase_auth_admin
ALTER USER supabase_auth_admin WITH CREATEROLE;

-- Create empty tables to avoid initial errors
CREATE TABLE IF NOT EXISTS auth.users (id uuid PRIMARY KEY);
CREATE TABLE IF NOT EXISTS auth.audit_log_entries (id uuid PRIMARY KEY);
CREATE TABLE IF NOT EXISTS storage.buckets (id text PRIMARY KEY);
CREATE TABLE IF NOT EXISTS storage.objects (id uuid PRIMARY KEY);

-- Grant usage on sequences
GRANT USAGE ON ALL SEQUENCES IN SCHEMA auth TO supabase_auth_admin;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA storage TO supabase_storage_admin;

-- Grant table permissions
GRANT ALL ON ALL TABLES IN SCHEMA auth TO supabase_auth_admin;
GRANT ALL ON ALL TABLES IN SCHEMA storage TO supabase_storage_admin;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO authenticator;

-- Notify about completion
SELECT 'Additional permissions set up successfully' as result; 