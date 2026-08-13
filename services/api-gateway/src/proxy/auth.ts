import type { Request, Response, NextFunction } from "express";
import axios from "axios";
import { config } from "../config.js";

export function createAuthProxy() {
  return async (request: Request, response: Response, _next: NextFunction) => {
    try {
      const targetUrl = `${config.AUTH_SERVICE_URL}${request.originalUrl}`;

      const axiosResponse = await axios({
        method: request.method,
        url: targetUrl,
        headers: {
          ...request.headers,
          host: undefined
        },
        data: request.body,
        responseType: "json",
        validateStatus: () => true
      });

      response.status(axiosResponse.status).json(axiosResponse.data);
    } catch (error) {
      console.error("[auth-proxy] Error proxying request:", error);
      response.status(502).json({
        error: {
          code: "AUTH_SERVICE_UNAVAILABLE",
          message: "Authentication service is unavailable"
        }
      });
    }
  };
}
