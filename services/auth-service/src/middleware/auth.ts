import jwt from "jsonwebtoken";
import type { Request, Response, NextFunction } from "express";
import { config } from "../config.js";
import { z } from "zod";

const jwtClaimsSchema = z.object({
  sub: z.string().min(1),
  username: z.string().min(1),
  roles: z.array(z.string())
});

export function authMiddleware(request: Request, response: Response, next: NextFunction) {
  const authorizationHeader = request.header("authorization");
  if (!authorizationHeader) {
    response.status(401).json({
      error: {
        code: "AUTH_REQUIRED",
        message: "Authorization header with Bearer token is required"
      }
    });
    return;
  }

  const [scheme, token] = authorizationHeader.split(" ");
  if (scheme?.toLowerCase() !== "bearer" || !token) {
    response.status(401).json({
      error: {
        code: "INVALID_AUTH_HEADER",
        message: "Authorization header must be in the format: Bearer <token>"
      }
    });
    return;
  }

  try {
    const verified = jwt.verify(token, config.JWT_SECRET);

    const parsedClaims = jwtClaimsSchema.safeParse(verified);
    if (!parsedClaims.success) {
      response.status(401).json({
        error: {
          code: "INVALID_TOKEN_CLAIMS",
          message: "Token claims are invalid"
        }
      });
      return;
    }

    request.user = {
      sub: parsedClaims.data.sub,
      username: parsedClaims.data.username,
      roles: parsedClaims.data.roles
    };

    next();
  } catch {
    response.status(401).json({
      error: {
        code: "INVALID_TOKEN",
        message: "Token is invalid or expired"
      }
    });
  }
}
