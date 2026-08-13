import { z } from "zod";

export const loginRequestSchema = z.object({
  username: z.string().min(1),
  password: z.string().min(1)
});

export const registerRequestSchema = z.object({
  username: z.string().min(3).max(50),
  email: z.string().email(),
  password: z.string().min(8)
});

export const jwtClaimsSchema = z.object({
  sub: z.string().min(1),
  username: z.string().min(1),
  roles: z.array(z.string())
});
