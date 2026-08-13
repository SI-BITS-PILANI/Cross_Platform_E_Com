import axios from "axios";
import { config } from "../config.js";

export interface ServiceHealthResult {
  status: string;
  latencyMs: number;
  error?: string;
}

export interface AggregatedHealthResponse {
  overall: "ok" | "degraded" | "down";
  timestamp: string;
  services: {
    auth: ServiceHealthResult;
  };
}

async function checkServiceHealth(
  serviceName: string,
  baseUrl: string,
  timeoutMs: number = 5000
): Promise<ServiceHealthResult> {
  const startTime = Date.now();
  try {
    const response = await axios.get(`${baseUrl}/health`, {
      timeout: timeoutMs,
      validateStatus: () => true
    });
    const latencyMs = Date.now() - startTime;

    if (response.status === 200) {
      return {
        status: "ok",
        latencyMs
      };
    } else {
      return {
        status: "down",
        latencyMs,
        error: `HTTP ${response.status}`
      };
    }
  } catch (error: any) {
    const latencyMs = Date.now() - startTime;
    return {
      status: "down",
      latencyMs,
      error: error.message || "Unknown error"
    };
  }
}

export async function getAggregatedHealth(): Promise<AggregatedHealthResponse> {
  const [authHealth] = await Promise.all([
    checkServiceHealth("auth", config.AUTH_SERVICE_URL)
  ]);

  const overallStatus: "ok" | "degraded" | "down" = authHealth.status === "ok" ? "ok" : "degraded";

  return {
    overall: overallStatus,
    timestamp: new Date().toISOString(),
    services: {
      auth: authHealth
    }
  };
}
