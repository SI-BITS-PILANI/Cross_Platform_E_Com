import { createApp } from "./app.js";
import { config, getSafeConfigForLog } from "./config.js";

const app = createApp();
const port = config.PORT;

console.log("Gateway config loaded", getSafeConfigForLog());

app.listen(port, () => {
  console.log(`api-gateway running on port ${port}`);
});

function handleShutdown() {
  process.exit(0);
}

process.on("SIGTERM", handleShutdown);
process.on("SIGINT", handleShutdown);
