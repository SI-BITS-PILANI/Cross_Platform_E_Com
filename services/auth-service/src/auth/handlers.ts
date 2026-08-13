import jwt from "jsonwebtoken";
import bcrypt from "bcrypt";
import type { Request, Response } from "express";
import { config } from "../config.js";
import { loginRequestSchema, registerRequestSchema } from "./schemas.js";
import { getUserByUsername, getUserByEmail, createUser } from "./userStore.js";
import type { UserRecord } from "../database.js";

interface TokenResponse {
  access_token: string;
  token_type: string;
  expires_in: number;
  user: {
    id: string;
    username: string;
    roles: string[];
  };
}

function issueToken(user: UserRecord): TokenResponse {
  const accessToken = jwt.sign(
    {
      username: user.username,
      roles: user.roles
    },
    config.JWT_SECRET,
    {
      subject: user.id,
      expiresIn: "1h"
    }
  );

  return {
    access_token: accessToken,
    token_type: "Bearer",
    expires_in: 3600,
    user: {
      id: user.id,
      username: user.username,
      roles: user.roles
    }
  };
}

export async function loginHandler(request: Request, response: Response) {
  const parsedPayload = loginRequestSchema.safeParse(request.body);
  if (!parsedPayload.success) {
    response.status(400).json({
      error: {
        code: "INVALID_LOGIN_PAYLOAD",
        message: "username and password are required"
      }
    });
    return;
  }

  try {
    const user = await getUserByUsername(parsedPayload.data.username);
    if (!user) {
      response.status(401).json({
        error: {
          code: "INVALID_CREDENTIALS",
          message: "Invalid username or password"
        }
      });
      return;
    }

    const isValid = await bcrypt.compare(parsedPayload.data.password, user.password_hash);
    if (!isValid) {
      response.status(401).json({
        error: {
          code: "INVALID_CREDENTIALS",
          message: "Invalid username or password"
        }
      });
      return;
    }

    response.status(200).json(issueToken(user));
  } catch (err) {
    console.error("[login] DB error:", err);
    response.status(500).json({
      error: {
        code: "INTERNAL_ERROR",
        message: "An error occurred during login"
      }
    });
  }
}

export async function registerHandler(request: Request, response: Response) {
  const parsedPayload = registerRequestSchema.safeParse(request.body);
  if (!parsedPayload.success) {
    response.status(400).json({
      error: {
        code: "INVALID_REGISTER_PAYLOAD",
        message: "username (3-50 chars), valid email, and password (8+ chars) are required"
      }
    });
    return;
  }

  const { username, email, password } = parsedPayload.data;

  try {
    const existingUser = await getUserByUsername(username);
    if (existingUser) {
      response.status(409).json({
        error: {
          code: "USERNAME_TAKEN",
          message: "That username is already taken"
        }
      });
      return;
    }

    const existingEmail = await getUserByEmail(email);
    if (existingEmail) {
      response.status(409).json({
        error: {
          code: "EMAIL_TAKEN",
          message: "An account with that email already exists"
        }
      });
      return;
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const createdUser = await createUser({
      username,
      email,
      passwordHash,
      roles: ["customer"]
    });

    response.status(201).json(issueToken(createdUser));
  } catch (err) {
    console.error("[register] error:", err);
    response.status(500).json({
      error: {
        code: "INTERNAL_ERROR",
        message: "An error occurred during registration"
      }
    });
  }
}

export function authMeHandler(request: Request, response: Response) {
  response.status(200).json({
    user: request.user
  });
}
