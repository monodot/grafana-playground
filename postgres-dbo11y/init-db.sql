-- Enable pg_stat_statements extension
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Verify the extension is installed
SELECT * FROM pg_extension WHERE extname = 'pg_stat_statements';

-- Create the db-o11y monitoring user with password
CREATE USER "db-o11y" WITH PASSWORD 'dbo11y-password';

-- Grant base monitoring privileges
GRANT pg_monitor TO "db-o11y";
GRANT pg_read_all_stats TO "db-o11y";

-- Disable tracking of monitoring user queries
ALTER ROLE "db-o11y" SET pg_stat_statements.track = 'none';

-- Grant read access to all data (includes all schemas and tables)
GRANT pg_read_all_data TO "db-o11y";

-- Verify configuration (these will show in logs)
SHOW track_activity_query_size;
SELECT * FROM pg_stat_statements LIMIT 1;
