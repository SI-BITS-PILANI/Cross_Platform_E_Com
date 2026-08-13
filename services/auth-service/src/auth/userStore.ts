import { runQuery, type UserRecord } from "../database.js";

export async function getUserByUsername(username: string): Promise<UserRecord | null> {
  const result = await runQuery<UserRecord>(
    "SELECT id, username, email, password_hash, roles, created_at, updated_at FROM users WHERE username = $1",
    [username]
  );
  return result.rows[0] ?? null;
}

export async function getUserByEmail(email: string): Promise<UserRecord | null> {
  const result = await runQuery<UserRecord>(
    "SELECT id, username, email, password_hash, roles, created_at, updated_at FROM users WHERE email = $1",
    [email]
  );
  return result.rows[0] ?? null;
}

export interface NewUser {
  username: string;
  email: string;
  passwordHash: string;
  roles: string[];
}

export async function createUser(user: NewUser): Promise<UserRecord> {
  const id = `c-${Date.now().toString(36)}`;
  const result = await runQuery<UserRecord>(
    `INSERT INTO users (id, username, email, password_hash, roles)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING id, username, email, password_hash, roles, created_at, updated_at`,
    [id, user.username, user.email, user.passwordHash, user.roles]
  );
  return result.rows[0];
}
