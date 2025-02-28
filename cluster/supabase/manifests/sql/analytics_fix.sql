-- Create _analytics schema
CREATE SCHEMA IF NOT EXISTS _analytics;

-- Set schema permissions
GRANT ALL ON SCHEMA _analytics TO supabase_admin;
GRANT USAGE ON SCHEMA _analytics TO service_role;

-- Create users table
CREATE TABLE IF NOT EXISTS logflare.users (
  id SERIAL PRIMARY KEY,
  email TEXT UNIQUE,
  provider TEXT,
  token TEXT,
  api_key TEXT UNIQUE,
  old_api_key TEXT,
  email_preferred BOOLEAN,
  name TEXT,
  image TEXT,
  email_me_product BOOLEAN,
  admin BOOLEAN,
  phone TEXT,
  bigquery_project_id TEXT,
  bigquery_dataset_location TEXT,
  bigquery_dataset_id TEXT,
  bigquery_udfs_hash TEXT,
  bigquery_processed_bytes_limit INTEGER,
  api_quota INTEGER,
  valid_google_account BOOLEAN,
  provider_uid TEXT,
  company TEXT,
  billing_enabled BOOLEAN,
  endpoints_beta BOOLEAN,
  metadata JSONB,
  preferences JSONB,
  inserted_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- Create sources table
CREATE TABLE IF NOT EXISTS logflare.sources (
  id SERIAL PRIMARY KEY,
  name TEXT,
  service_name TEXT,
  token TEXT UNIQUE,
  public_token TEXT,
  favorite BOOLEAN,
  bigquery_table_ttl INTEGER,
  api_quota INTEGER,
  webhook_notification_url TEXT,
  slack_hook_url TEXT,
  bq_table_partition_type TEXT,
  custom_event_message_keys TEXT[],
  log_events_updated_at TIMESTAMP,
  notifications_every INTEGER,
  lock_schema BOOLEAN,
  validate_schema BOOLEAN,
  drop_lql_filters TEXT,
  drop_lql_string TEXT,
  v2_pipeline BOOLEAN,
  suggested_keys TEXT[],
  transform_copy_fields TEXT,
  user_id INTEGER REFERENCES logflare.users(id),
  notifications JSONB,
  inserted_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- Add sample data
INSERT INTO logflare.users (email, api_key, inserted_at, updated_at)
VALUES ('admin@example.com', 'test-api-key', NOW(), NOW())
ON CONFLICT DO NOTHING;

INSERT INTO logflare.sources (name, token, user_id, log_events_updated_at, inserted_at, updated_at)
VALUES ('Default Source', 'default-source-token', 1, NOW(), NOW(), NOW())
ON CONFLICT DO NOTHING; 