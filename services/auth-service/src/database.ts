import { Pool } from "pg";
import { config } from "./config.js";

const pool = new Pool({
  host: config.USER_DB_HOST,
  port: config.USER_DB_PORT,
  database: config.USER_DB_NAME,
  user: config.USER_DB_USER,
  password: config.USER_DB_PASSWORD,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000
});

pool.on("error", (err) => {
  console.error("[database] Unexpected error on idle client", err);
});

export interface UserRecord {
  id: string;
  username: string;
  email: string;
  password_hash: string;
  roles: string[];
  created_at: string;
  updated_at: string;
}

export async function runQuery<T = any>(sql: string, params: any[] = []): Promise<{ rows: T[] }> {
  const result = await pool.query(sql, params);
  return { rows: result.rows as T[] };
}

export async function checkDatabaseHealth(): Promise<void> {
  await pool.query("SELECT 1");
}

export async function closeDatabaseConnection(): Promise<void> {
  await pool.end();
}
