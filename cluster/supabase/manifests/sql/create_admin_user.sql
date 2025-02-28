-- Create supabase_admin user

-- Create the user
CREATE ROLE supabase_admin WITH LOGIN PASSWORD 'postgres' SUPERUSER;

-- Grant necessary permissions
GRANT ALL PRIVILEGES ON DATABASE postgres TO supabase_admin;

-- Notify about completion
SELECT 'supabase_admin user created successfully' as result; 