-- Create necessary Supabase users and roles
-- Default password is 'postgres' for all users

-- Create the authenticator role (used by PostgREST)
CREATE ROLE authenticator WITH NOINHERIT LOGIN PASSWORD 'postgres';

-- Create supabase_auth_admin (used by GoTrue auth service)
CREATE ROLE supabase_auth_admin WITH LOGIN PASSWORD 'postgres';
GRANT ALL PRIVILEGES ON DATABASE postgres TO supabase_auth_admin;

-- Create supabase_storage_admin (used by Storage service)
CREATE ROLE supabase_storage_admin WITH LOGIN PASSWORD 'postgres';
GRANT ALL PRIVILEGES ON DATABASE postgres TO supabase_storage_admin;

-- Additional common Supabase roles
CREATE ROLE anon;
CREATE ROLE authenticated;
CREATE ROLE service_role;

-- Grant roles to authenticator
GRANT anon TO authenticator;
GRANT authenticated TO authenticator;
GRANT service_role TO authenticator;

-- Notify about completion
SELECT 'Supabase users and roles created successfully' as result; 