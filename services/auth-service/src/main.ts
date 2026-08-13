import { createApp } from "./app.js";
import { config, getSafeConfigForLog } from "./config.js";
import { seedIfEmpty } from "./auth/demoUsers.js";
import { closeDatabaseConnection } from "./database.js";

const app = createApp();
const port = config.PORT;

console.log("Auth service config loaded", getSafeConfigForLog());

seedIfEmpty()
  .then(() => {
    app.listen(port, () => {
      console.log(`auth-service running on port ${port}`);
    });
  })
  .catch((err) => {
    console.error("[startup] Failed to seed database:", err);
    process.exit(1);
  });

function handleShutdown() {
  closeDatabaseConnection()
    .catch((err) => console.error("[shutdown] Database close error:", err))
    .finally(() => process.exit(0));
}

process.on("SIGTERM", handleShutdown);
process.on("SIGINT", handleShutdown);
