/**
 * Integration tests for authentication endpoints.
 * Spins up a real Express server on a random port per describe block.
 * Requires a PostgreSQL database (see .env.test) pre-configured with the
 * user_db database, user_user role, and password user_password.
 */
import { describe, test, before, after } from "node:test";
import assert from "node:assert/strict";
import { createServer } from "node:http";
import type { AddressInfo } from "node:net";
import { createApp } from "../app.js";
import { seedIfEmpty } from "../auth/demoUsers.js";
import { runQuery } from "../database.js";

async function startTestServer() {
  const app = createApp();
  const server = createServer(app);
  await new Promise<void>((resolve) => server.listen(0, "127.0.0.1", resolve));
  const port = (server.address() as AddressInfo).port;
  return { server, baseUrl: `http://127.0.0.1:${port}` };
}

const TEST_USER = "testuser_reg";
const TEST_EMAIL = "testuser_reg@example.com";
const TEST_PASSWORD = "TestPass123!";

async function cleanupTestUser() {
  try {
    await runQuery("DELETE FROM users WHERE username = $1 OR email = $2", [
      TEST_USER,
      TEST_EMAIL
    ]);
  } catch {
    /* ignore cleanup errors */
  }
}

// ---------------------------------------------------------------------------
// POST /auth/register
// ---------------------------------------------------------------------------
describe("POST /auth/register", () => {
  let baseUrl: string;
  let server: ReturnType<typeof createServer>;

  before(async () => {
    await seedIfEmpty();
    ({ server, baseUrl } = await startTestServer());
  });

  after(() => new Promise<void>((resolve) => server.close(resolve)));

  test("returns 201 with token response for valid registration", async () => {
    await cleanupTestUser();
    const res = await fetch(`${baseUrl}/auth/register`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        username: TEST_USER,
        email: TEST_EMAIL,
        password: TEST_PASSWORD
      })
    });
    assert.equal(res.status, 201);
    const body: any = await res.json();
    assert.ok(
      typeof body.access_token === "string" && body.access_token.length > 0,
      "access_token must be a non-empty string"
    );
    assert.equal(body.token_type, "Bearer");
    assert.equal(body.expires_in, 3600);
    assert.equal(body.user.username, TEST_USER);
    assert.deepEqual(body.user.roles, ["customer"]);
  });

  test("returns 400 when body fields are absent", async () => {
    const res = await fetch(`${baseUrl}/auth/register`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({})
    });
    assert.equal(res.status, 400);
    const body: any = await res.json();
    assert.equal(body.error.code, "INVALID_REGISTER_PAYLOAD");
  });

  test("returns 400 when username is too short", async () => {
    const res = await fetch(`${baseUrl}/auth/register`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        username: "ab",
        email: "valid@email.com",
        password: "password123"
      })
    });
    assert.equal(res.status, 400);
    const body: any = await res.json();
    assert.equal(body.error.code, "INVALID_REGISTER_PAYLOAD");
  });

  test("returns 400 when email is invalid", async () => {
    const res = await fetch(`${baseUrl}/auth/register`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        username: "validuser123",
        email: "not-an-email",
        password: "password123"
      })
    });
    assert.equal(res.status, 400);
    const body: any = await res.json();
    assert.equal(body.error.code, "INVALID_REGISTER_PAYLOAD");
  });

  test("returns 400 when password is too short", async () => {
    const res = await fetch(`${baseUrl}/auth/register`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        username: "validuser456",
        email: "valid2@email.com",
        password: "short"
      })
    });
    assert.equal(res.status, 400);
    const body: any = await res.json();
    assert.equal(body.error.code, "INVALID_REGISTER_PAYLOAD");
  });

  test("returns 409 when username is already taken", async () => {
    await cleanupTestUser();
    // First registration succeeds
    await fetch(`${baseUrl}/auth/register`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        username: TEST_USER,
        email: "different@example.com",
        password: TEST_PASSWORD
      })
    });
    // Second registration with same username fails
    const res = await fetch(`${baseUrl}/auth/register`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        username: TEST_USER,
        email: "another@example.com",
        password: TEST_PASSWORD
      })
    });
    assert.equal(res.status, 409);
    const body: any = await res.json();
    assert.equal(body.error.code, "USERNAME_TAKEN");
  });

  test("returns 409 when email is already taken", async () => {
    await cleanupTestUser();
    // First registration succeeds
    await fetch(`${baseUrl}/auth/register`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        username: "different_user",
        email: TEST_EMAIL,
        password: TEST_PASSWORD
      })
    });
    // Second registration with same email fails
    const res = await fetch(`${baseUrl}/auth/register`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        username: "another_user",
        email: TEST_EMAIL,
        password: TEST_PASSWORD
      })
    });
    assert.equal(res.status, 409);
    const body: any = await res.json();
    assert.equal(body.error.code, "EMAIL_TAKEN");
  });

  after(async () => {
    await cleanupTestUser();
  });
});

// ---------------------------------------------------------------------------
// POST /auth/login
// ---------------------------------------------------------------------------
describe("POST /auth/login", () => {
  let baseUrl: string;
  let server: ReturnType<typeof createServer>;

  before(async () => {
    await seedIfEmpty();
    ({ server, baseUrl } = await startTestServer());
  });

  after(() => new Promise<void>((resolve) => server.close(resolve)));

  test("returns 400 when body fields are absent", async () => {
    const res = await fetch(`${baseUrl}/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({})
    });
    assert.equal(res.status, 400);
    const body: any = await res.json();
    assert.equal(body.error.code, "INVALID_LOGIN_PAYLOAD");
  });

  test("returns 400 when username or password is empty string", async () => {
    const res = await fetch(`${baseUrl}/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username: "", password: "" })
    });
    assert.equal(res.status, 400);
    const body: any = await res.json();
    assert.equal(body.error.code, "INVALID_LOGIN_PAYLOAD");
  });

  test("returns 401 for unknown username", async () => {
    const res = await fetch(`${baseUrl}/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username: "nobody", password: "any" })
    });
    assert.equal(res.status, 401);
    const body: any = await res.json();
    assert.equal(body.error.code, "INVALID_CREDENTIALS");
  });

  test("returns 401 for valid username but wrong password", async () => {
    const res = await fetch(`${baseUrl}/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username: "alice", password: "wrong" })
    });
    assert.equal(res.status, 401);
    const body: any = await res.json();
    assert.equal(body.error.code, "INVALID_CREDENTIALS");
  });

  test("returns 200 with full token response for alice", async () => {
    const res = await fetch(`${baseUrl}/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username: "alice", password: "password123" })
    });
    assert.equal(res.status, 200);
    const body: any = await res.json();
    assert.ok(
      typeof body.access_token === "string" && body.access_token.length > 0,
      "access_token must be a non-empty string"
    );
    assert.equal(body.token_type, "Bearer");
    assert.equal(body.expires_in, 3600);
    assert.equal(body.user.username, "alice");
    assert.equal(body.user.id, "c-001");
    assert.deepEqual(body.user.roles, ["customer"]);
  });

  test("returns 200 with admin role for admin credentials", async () => {
    const res = await fetch(`${baseUrl}/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username: "admin", password: "admin123" })
    });
    assert.equal(res.status, 200);
    const body: any = await res.json();
    assert.ok(body.user.roles.includes("admin"), "admin user must have admin role");
    assert.ok(body.user.roles.includes("customer"), "admin user must also have customer role");
  });

  test("returns 200 for a user registered via /auth/register", async () => {
    await cleanupTestUser();
    // Register
    const regRes = await fetch(`${baseUrl}/auth/register`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        username: TEST_USER,
        email: TEST_EMAIL,
        password: TEST_PASSWORD
      })
    });
    assert.equal(regRes.status, 201);
    // Login with registered credentials
    const loginRes = await fetch(`${baseUrl}/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username: TEST_USER, password: TEST_PASSWORD })
    });
    assert.equal(loginRes.status, 200);
    const body: any = await loginRes.json();
    assert.equal(body.user.username, TEST_USER);
    assert.deepEqual(body.user.roles, ["customer"]);
  });
});

// ---------------------------------------------------------------------------
// GET /auth/me
// ---------------------------------------------------------------------------
describe("GET /auth/me", () => {
  let baseUrl: string;
  let server: ReturnType<typeof createServer>;
  let aliceToken: string;

  before(async () => {
    await seedIfEmpty();
    ({ server, baseUrl } = await startTestServer());
    const loginRes = await fetch(`${baseUrl}/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username: "alice", password: "password123" })
    });
    const loginBody: any = await loginRes.json();
    aliceToken = loginBody.access_token;
  });

  after(() => new Promise<void>((resolve) => server.close(resolve)));

  test("returns 401 AUTH_REQUIRED when no authorization header", async () => {
    const res = await fetch(`${baseUrl}/auth/me`);
    assert.equal(res.status, 401);
    const body: any = await res.json();
    assert.equal(body.error.code, "AUTH_REQUIRED");
  });

  test("returns 401 INVALID_AUTH_HEADER when scheme is not Bearer", async () => {
    const res = await fetch(`${baseUrl}/auth/me`, {
      headers: { Authorization: "Basic sometoken" }
    });
    assert.equal(res.status, 401);
    const body: any = await res.json();
    assert.equal(body.error.code, "INVALID_AUTH_HEADER");
  });

  test("returns 401 for a structurally invalid JWT", async () => {
    const res = await fetch(`${baseUrl}/auth/me`, {
      headers: { Authorization: "Bearer not.a.real.jwt" }
    });
    assert.equal(res.status, 401);
  });

  test("returns 200 with user claims for a valid alice token", async () => {
    const res = await fetch(`${baseUrl}/auth/me`, {
      headers: { Authorization: `Bearer ${aliceToken}` }
    });
    assert.equal(res.status, 200);
    const body: any = await res.json();
    assert.equal(body.user.username, "alice");
    assert.equal(body.user.sub, "c-001");
    assert.deepEqual(body.user.roles, ["customer"]);
  });
});
