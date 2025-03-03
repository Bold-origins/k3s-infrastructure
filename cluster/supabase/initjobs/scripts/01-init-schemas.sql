-- Create necessary schemas
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS realtime;
CREATE SCHEMA IF NOT EXISTS storage;
CREATE SCHEMA IF NOT EXISTS _analytics;
CREATE SCHEMA IF NOT EXISTS logflare;

-- Create necessary roles if they don't exist
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_auth_admin') THEN
    CREATE ROLE supabase_auth_admin WITH LOGIN PASSWORD 'postgres';
  END IF;
  
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_storage_admin') THEN
    CREATE ROLE supabase_storage_admin WITH LOGIN PASSWORD 'postgres';
  END IF;
  
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_realtime_admin') THEN
    CREATE ROLE supabase_realtime_admin WITH LOGIN PASSWORD 'postgres';
  END IF;
END
$$;

-- Grant schema ownership
ALTER SCHEMA auth OWNER TO supabase_auth_admin;
ALTER SCHEMA storage OWNER TO supabase_storage_admin;
ALTER SCHEMA realtime OWNER TO supabase_realtime_admin;

-- Grant necessary permissions
GRANT ALL ON ALL TABLES IN SCHEMA auth TO supabase_auth_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA auth TO supabase_auth_admin;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA auth TO supabase_auth_admin;

GRANT ALL ON ALL TABLES IN SCHEMA storage TO supabase_storage_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA storage TO supabase_storage_admin;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA storage TO supabase_storage_admin;

GRANT ALL ON ALL TABLES IN SCHEMA realtime TO supabase_realtime_admin;
GRANT ALL ON ALL SEQUENCES IN SCHEMA realtime TO supabase_realtime_admin;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA realtime TO supabase_realtime_admin;

-- Set default privileges
ALTER DEFAULT PRIVILEGES IN SCHEMA auth GRANT ALL ON TABLES TO supabase_auth_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA auth GRANT ALL ON SEQUENCES TO supabase_auth_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA auth GRANT ALL ON FUNCTIONS TO supabase_auth_admin;

ALTER DEFAULT PRIVILEGES IN SCHEMA storage GRANT ALL ON TABLES TO supabase_storage_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA storage GRANT ALL ON SEQUENCES TO supabase_storage_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA storage GRANT ALL ON FUNCTIONS TO supabase_storage_admin;

ALTER DEFAULT PRIVILEGES IN SCHEMA realtime GRANT ALL ON TABLES TO supabase_realtime_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA realtime GRANT ALL ON SEQUENCES TO supabase_realtime_admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA realtime GRANT ALL ON FUNCTIONS TO supabase_realtime_admin;

-- Grant superuser permissions (needed for migrations)
ALTER USER supabase_auth_admin WITH SUPERUSER;
ALTER USER supabase_storage_admin WITH SUPERUSER;
ALTER USER supabase_realtime_admin WITH SUPERUSER;

-- Set search paths
ALTER USER supabase_auth_admin SET search_path TO auth,public;
ALTER USER supabase_storage_admin SET search_path TO storage,public;
ALTER USER supabase_realtime_admin SET search_path TO realtime,public;
ALTER DATABASE postgres SET search_path TO realtime,public;

-- Create realtime schema migrations table
CREATE TABLE IF NOT EXISTS realtime.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);
ALTER TABLE realtime.schema_migrations OWNER TO supabase_realtime_admin; 