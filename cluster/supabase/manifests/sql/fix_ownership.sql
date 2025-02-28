-- Fix ownership for Auth and Storage tables

-- For auth schema
ALTER TABLE auth.users OWNER TO supabase_auth_admin;
ALTER TABLE auth.audit_log_entries OWNER TO supabase_auth_admin;
ALTER SCHEMA auth OWNER TO supabase_auth_admin;

-- For storage schema
ALTER TABLE storage.buckets OWNER TO supabase_storage_admin;
ALTER TABLE storage.objects OWNER TO supabase_storage_admin;
ALTER SCHEMA storage OWNER TO supabase_storage_admin;

-- Notify about completion
SELECT 'Table ownership fixed successfully' as result; 