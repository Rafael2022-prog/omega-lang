-- OMEGA PostgreSQL initialization script (minimal)
-- This file ensures Docker Compose can mount an init script without errors.
-- The POSTGRES_DB and POSTGRES_USER are set via environment; below are optional.

-- Example: enable useful extensions if available
DO $$
BEGIN
  -- Uncomment extensions below if the image supports them
  -- PERFORM 1 FROM pg_available_extensions WHERE name = 'uuid-ossp';
  -- IF FOUND THEN
  --   EXECUTE 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp"';
  -- END IF;
END$$;

-- Placeholder table for basic connectivity tests
CREATE TABLE IF NOT EXISTS omega_init_check (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMP DEFAULT NOW()
);