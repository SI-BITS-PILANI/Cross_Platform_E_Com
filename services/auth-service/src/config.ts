import dotenv from "dotenv";
import { z } from "zod";

dotenv.config();

const envSchema = z.object({
  PORT: z.coerce.number().int().positive().default(3001),
  JWT_SECRET: z.string().min(8, "JWT_SECRET must be at least 8 characters long"),
  USER_DB_HOST: z.string().default("localhost"),
  USER_DB_PORT: z.coerce.number().int().positive().default(5432),
  USER_DB_NAME: z.string(),
  USER_DB_USER: z.string(),
  USER_DB_PASSWORD: z.string()
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  const issueMessages = parsed.error.issues
    .map((issue) => {
      const path = issue.path.join(".") || "env";
      return `- ${path}: ${issue.message}`;
    })
    .join("\n");

  throw new Error(`Invalid environment configuration:\n${issueMessages}`);
}

export const config = parsed.data;

export function getSafeConfigForLog() {
  return {
    PORT: config.PORT,
    USER_DB_HOST: config.USER_DB_HOST,
    USER_DB_PORT: config.USER_DB_PORT,
    USER_DB_NAME: config.USER_DB_NAME,
    USER_DB_USER: config.USER_DB_USER,
    JWT_SECRET: "[hidden]",
    USER_DB_PASSWORD: "[hidden]"
  };
}
