import bcrypt from "bcrypt";
import { runQuery, type UserRecord } from "../database.js";

export interface DemoUserDef {
  id: string;
  username: string;
  email: string;
  password: string;
  roles: string[];
}

export const demoUsers: DemoUserDef[] = [
  {
    id: "c-001",
    username: "alice",
    password: "password123",
    email: "alice@example.com",
    roles: ["customer"]
  },
  {
    id: "c-admin",
    username: "admin",
    password: "admin123",
    email: "admin@example.com",
    roles: ["admin", "customer"]
  }
];

export async function seedDemoUsers(): Promise<void> {
  for (const user of demoUsers) {
    const existing = await runQuery(
      "SELECT id FROM users WHERE username = $1",
      [user.username]
    );
    if (existing.rows.length > 0) continue;

    const passwordHash = await bcrypt.hash(user.password, 10);
    await runQuery(
      `INSERT INTO users (id, username, email, password_hash, roles)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (username) DO NOTHING`,
      [user.id, user.username, user.email, passwordHash, user.roles]
    );
  }
  console.log("[seed] Demo users ensured");
}

export async function ensureUsersTable(): Promise<void> {
  await runQuery(`
    CREATE TABLE IF NOT EXISTS users (
      id VARCHAR(50) PRIMARY KEY,
      username VARCHAR(50) UNIQUE NOT NULL,
      email VARCHAR(255) UNIQUE,
      password_hash VARCHAR(255) NOT NULL,
      roles TEXT[] NOT NULL DEFAULT ARRAY['customer'],
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `);
  await runQuery(`
    CREATE UNIQUE INDEX IF NOT EXISTS uq_users_username ON users(username)
  `);
  await runQuery(`
    CREATE UNIQUE INDEX IF NOT EXISTS uq_users_email ON users(email)
  `);
  console.log("[seed] users table ensured");
}

export async function seedIfEmpty(): Promise<void> {
  await ensureUsersTable();
  await seedDemoUsers();
}
