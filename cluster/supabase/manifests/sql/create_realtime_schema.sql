-- Set up the realtime schema properly

-- Make sure schema exists
CREATE SCHEMA IF NOT EXISTS realtime;

-- Create realtime_migrations table for Ecto
CREATE TABLE IF NOT EXISTS realtime.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);

ALTER TABLE realtime.schema_migrations OWNER TO postgres;

-- Allow realtime service to connect
CREATE ROLE IF NOT EXISTS supabase_realtime_admin WITH LOGIN PASSWORD 'postgres';
GRANT ALL PRIVILEGES ON DATABASE postgres TO supabase_realtime_admin;
GRANT ALL PRIVILEGES ON SCHEMA realtime TO supabase_realtime_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA realtime TO supabase_realtime_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA realtime TO supabase_realtime_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA realtime TO supabase_realtime_admin;
ALTER SCHEMA realtime OWNER TO supabase_realtime_admin;

-- Grant usage on schema
GRANT USAGE ON SCHEMA realtime TO PUBLIC;

-- Notify about completion
SELECT 'Realtime schema setup completed successfully' as result; 