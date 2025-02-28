-- Create system_metrics table for Logflare/Analytics
CREATE TABLE IF NOT EXISTS system_metrics (
    id SERIAL PRIMARY KEY,
    all_logs_logged BIGINT NOT NULL DEFAULT 0,
    node VARCHAR(255) NOT NULL UNIQUE,
    inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Grant permissions to supabase_admin
GRANT ALL PRIVILEGES ON TABLE system_metrics TO supabase_admin;

-- Create an index on the node column for better performance
CREATE INDEX IF NOT EXISTS system_metrics_node_idx ON system_metrics(node);

-- Add a sample record to prevent initialization errors
INSERT INTO system_metrics (all_logs_logged, node)
VALUES (0, 'logflare') 
ON CONFLICT (node) DO NOTHING;

SELECT 'Analytics tables created successfully' as result; 