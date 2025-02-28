-- Drop the simple tables we created so migrations can create the proper ones

-- Drop auth tables
DROP TABLE IF EXISTS auth.users;
DROP TABLE IF EXISTS auth.audit_log_entries;

-- Drop storage tables
DROP TABLE IF EXISTS storage.buckets;
DROP TABLE IF EXISTS storage.objects;

-- Notify about completion
SELECT 'Simple tables dropped successfully' as result; 