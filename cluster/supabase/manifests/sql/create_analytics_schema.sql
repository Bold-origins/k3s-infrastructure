-- Set up the logflare schema properly

-- Create logflare schema
CREATE SCHEMA IF NOT EXISTS logflare;

-- Create schema_migrations table for Ecto
CREATE TABLE IF NOT EXISTS logflare.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);

ALTER TABLE logflare.schema_migrations OWNER TO postgres;

-- Move system_metrics table to logflare schema
ALTER TABLE IF EXISTS system_metrics SET SCHEMA logflare;

-- Grant permissions to supabase_admin
GRANT ALL PRIVILEGES ON SCHEMA logflare TO supabase_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA logflare TO supabase_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA logflare TO supabase_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA logflare TO supabase_admin;

-- Set schema owner
ALTER SCHEMA logflare OWNER TO supabase_admin;

-- Grant usage on schema
GRANT USAGE ON SCHEMA logflare TO PUBLIC;

-- Notify about completion
SELECT 'Logflare schema setup completed successfully' as result; 