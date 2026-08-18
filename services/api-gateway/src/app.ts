import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import { authMiddleware } from "./middleware/auth.js";
import { requireRole } from "./middleware/authorization.js";
import { createRateLimiter } from "./middleware/rateLimit.js";
import { getAggregatedHealth } from "./health/aggregator.js";
import { errorHandler } from "./errors/errorHandler.js";
import { createAuthProxy } from "./proxy/auth.js";
import { createCatalogProxy } from "./proxy/catalog.js";

export function createApp() {
  const app = express();
  const limiter = createRateLimiter();

  app.use(express.json());
  app.use(cors());
  app.use(helmet());
  app.use(limiter);
  app.use(
    morgan('{"method":":method","path":":url","status":":status","latency_ms":":response-time[digits]"}')
  );

  app.use("/auth", createAuthProxy());
  app.use("/api/v1/products", createCatalogProxy());
  app.use("/api/v2/products", createCatalogProxy());
  app.use("/api/v1/brands", createCatalogProxy());
  app.use("/api/v1/categories", createCatalogProxy());
  app.use("/api/v1/price-range", createCatalogProxy());

  app.get("/health", (_request, response) => {
    response.status(200).json({
      service: "api-gateway",
      status: "ok"
    });
  });

  app.use(authMiddleware);

  app.get("/health/all", async (_request, response) => {
    const aggregatedHealth = await getAggregatedHealth();
    const statusCode =
      aggregatedHealth.overall === "ok" ? 200 : 503;
    response.status(statusCode).json(aggregatedHealth);
  });

  app.get("/api/v1/protected", requireRole("customer"), (_request, response) => {
    response.status(200).json({
      message: "You have access to protected routes",
      user: _request.user
    });
  });

  // Placeholder: other teams will add additional proxy routes here
  // e.g. app.use("/api/v1/orders", orderProxy)

  app.use(errorHandler);

  return app;
}
