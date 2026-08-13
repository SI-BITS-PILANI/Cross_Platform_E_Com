/**
 * Integration tests for gateway health endpoints and auth middleware.
 * Spins up a real Express server on a random port per describe block.
 * Requires auth-service to be reachable at AUTH_SERVICE_URL for /health/all.
 */
import { describe, test, before, after } from "node:test";
import assert from "node:assert/strict";
import { createServer } from "node:http";
import type { AddressInfo } from "node:net";
import { createApp } from "../app.js";

async function startTestServer() {
  const app = createApp();
  const server = createServer(app);
  await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
  const port = (server.address() as AddressInfo).port;
  return { server, baseUrl: `http://127.0.0.1:${port}` };
}

// ---------------------------------------------------------------------------
// GET /health  (public, no auth required)
// ---------------------------------------------------------------------------
describe("GET /health", () => {
  let baseUrl: string;
  let server: ReturnType<typeof createServer>;

  before(async () => {
    ({ server, baseUrl } = await startTestServer());
  });

  after(() => new Promise<void>((resolve) => server.close(resolve)));

  test("returns 200 with gateway status ok — no authentication needed", async () => {
    const res = await fetch(`${baseUrl}/health`);
    assert.equal(res.status, 200);
    const body: any = await res.json();
    assert.equal(body.service, "api-gateway");
    assert.equal(body.status, "ok");
  });
});

// ---------------------------------------------------------------------------
// GET /health/all  (requires Bearer token)
// ---------------------------------------------------------------------------
describe("GET /health/all", () => {
  let baseUrl: string;
  let server: ReturnType<typeof createServer>;
  let aliceToken: string;

  before(async () => {
    ({ server, baseUrl } = await startTestServer());
    const loginRes = await fetch(`${baseUrl}/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username: "alice", password: "password123" }),
    });
    const loginBody: any = await loginRes.json();
    aliceToken = loginBody.access_token;
  });

  after(() => new Promise<void>((resolve) => server.close(resolve)));

  test("returns 401 AUTH_REQUIRED without a token", async () => {
    const res = await fetch(`${baseUrl}/health/all`);
    assert.equal(res.status, 401);
    const body: any = await res.json();
    assert.equal(body.error.code, "AUTH_REQUIRED");
  });

  test("returns 200 or 503 with aggregated health structure for a valid token", async () => {
    if (!aliceToken) {
      console.warn("Skipping /health/all authenticated test — auth-service is not reachable");
      return;
    }
    const res = await fetch(`${baseUrl}/health/all`, {
      headers: { Authorization: `Bearer ${aliceToken}` },
    });
    assert.ok(
      res.status === 200 || res.status === 503,
      `Expected 200 or 503, got ${res.status}`
    );
    const body: any = await res.json();
    assert.ok(
      ["ok", "degraded", "down"].includes(body.overall),
      `overall must be ok/degraded/down, got: ${body.overall}`
    );
    assert.ok(typeof body.timestamp === "string");
    assert.ok(body.services?.auth, "auth service entry must be present");
  });
});

// ---------------------------------------------------------------------------
// Public route bypass — /auth/* should not demand auth
// ---------------------------------------------------------------------------
describe("Public route auth bypass", () => {
  let baseUrl: string;
  let server: ReturnType<typeof createServer>;

  before(async () => {
    ({ server, baseUrl } = await startTestServer());
  });

  after(() => new Promise<void>((resolve) => server.close(resolve)));

  test("POST /auth/login does not return 401 without a token", async () => {
    const res = await fetch(`${baseUrl}/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username: "alice", password: "password123" }),
    });
    assert.notEqual(res.status, 401, "Auth login must not require gateway auth");
  });

  test("GET /api/v1/protected returns 401 without a token (protected route)", async () => {
    const res = await fetch(`${baseUrl}/api/v1/protected`);
    assert.equal(res.status, 401);
  });
});
