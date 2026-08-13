-- Dedicated credentials + database for user authentication (auth-service).
-- Idempotent: safe to run multiple times.
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'user_user') THEN
    CREATE ROLE user_user WITH LOGIN PASSWORD 'user_password';
  END IF;
END
$$;

SELECT 'CREATE DATABASE user_db OWNER user_user'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'user_db')\\gexec

\\c user_db

SET ROLE user_user;

-- User accounts table for the auth-service auth layer.
CREATE TABLE IF NOT EXISTS users (
  id VARCHAR(50) PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  roles TEXT[] NOT NULL DEFAULT ARRAY['customer'],
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_users_username ON users(username);
CREATE UNIQUE INDEX IF NOT EXISTS uq_users_email ON users(email);

-- Seed demo users with bcrypt-hashed passwords (cost factor 10).
-- alice: password123, admin: admin123
INSERT INTO users (id, username, email, password_hash, roles) VALUES
  ('c-001', 'alice', 'alice@example.com', '$2b$10$cfuBAbw6bayyKegiNSlYi.O4hyO1YpJ/Si1MvgCLKAsfm1secA9pu', ARRAY['customer']),
  ('c-admin', 'admin', 'admin@example.com', '$2b$10$q7PT/Ns.fND/F6jRhePd5uH1iK7MDrEQnTlbMWM8RNiqyeDqrQJ/a', ARRAY['admin', 'customer'])
ON CONFLICT (username) DO NOTHING;

RESET ROLE;
