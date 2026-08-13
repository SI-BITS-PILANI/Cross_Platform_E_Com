import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import { authMiddleware } from "./middleware/auth.js";
import { authMeHandler, loginHandler, registerHandler } from "./auth/handlers.js";
import { errorHandler } from "./errors/errorHandler.js";

export function createApp() {
  const app = express();

  app.use(express.json());
  app.use(cors());
  app.use(helmet());
  app.use(
    morgan('{"method":":method","path":":url","status":":status","latency_ms":":response-time[digits]"}')
  );

  app.post("/auth/register", registerHandler);
  app.post("/auth/login", loginHandler);
  app.get("/auth/me", authMiddleware, authMeHandler);

  app.get("/health", (_request, response) => {
    response.status(200).json({
      service: "auth-service",
      status: "ok"
    });
  });

  app.use(errorHandler);

  return app;
}
