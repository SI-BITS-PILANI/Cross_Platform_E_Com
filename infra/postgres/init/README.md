# Database Init Scripts

Place SQL initialization scripts for each service's database here.
Docker Compose mounts this directory to `/docker-entrypoint-initdb.d/` in the PostgreSQL container.

## Naming Convention

Use numbered prefixes to control execution order:
- `01-init-<service>-db.sql` — create database and tables for <service>
- `02-init-<service>-db.sql` — etc.

## Current Scripts

- `01-init-users-db.sql` — creates `user_db` and `users` table for auth-service
