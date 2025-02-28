-- Set up the realtime role and permissions

-- Create the role (without IF NOT EXISTS)
CREATE ROLE supabase_realtime_admin WITH LOGIN PASSWORD 'postgres';

-- Grant necessary permissions
GRANT ALL PRIVILEGES ON DATABASE postgres TO supabase_realtime_admin;
GRANT ALL PRIVILEGES ON SCHEMA realtime TO supabase_realtime_admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA realtime TO supabase_realtime_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA realtime TO supabase_realtime_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA realtime TO supabase_realtime_admin;
ALTER SCHEMA realtime OWNER TO supabase_realtime_admin;

-- Notify about completion
SELECT 'Realtime role setup completed successfully' as result; 