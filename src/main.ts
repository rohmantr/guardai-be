import express from "express";
import { AppDataSource } from "./common/database";
import { Logger } from "./common/logger";
import { requestLogger } from "./common/request-logger";
import { errorHandler } from "./common/error-handler";
import { setupGracefulShutdown } from "./common/shutdown";

const app = express();
const port = process.env.PORT ?? 3000;

// 1. Middleware
app.use(express.json());
app.use(requestLogger);

// 2. Routes
app.get("/health", (_req, res) => {
  res.json({
    status: "ok",
    service: "guardai-be",
    timestamp: new Date().toISOString(),
  });
});

// Test route to verify error handling
app.get("/error-test", () => {
  throw new Error("This is a simulated uncaught test error!");
});

// 3. Error Handling Middleware (must be registered after all route handlers)
app.use(errorHandler);

// 4. Initialize Database and start Server
async function bootstrap() {
  try {
    Logger.info("Initializing database connection...");
    await AppDataSource.initialize();
    Logger.info("Database connection initialized successfully.");

    const server = app.listen(port, () => {
      Logger.info(`guardai-be running on http://localhost:${port}`);
    });

    // Setup Graceful Shutdown (SIGINT, SIGTERM, uncaught exceptions/rejections)
    setupGracefulShutdown(server);
  } catch (error) {
    Logger.error("Failed to bootstrap the application", error);
    process.exit(1);
  }
}

bootstrap();
