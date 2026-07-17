import { Server } from "http";
import { AppDataSource } from "../database";
import { Logger } from "./logger";

export function setupGracefulShutdown(server: Server) {
  let shuttingDown = false;

  const shutdown = async (signal: string) => {
    if (shuttingDown) return;
    shuttingDown = true;

    Logger.warn("Received shutdown signal. Starting graceful shutdown...", {
      signal,
    });

    // Set a force exit watchdog timer (10s)
    const forceExitTimeout = setTimeout(() => {
      Logger.error("Graceful shutdown timed out. Forcing process exit.");
      process.exit(1);
    }, 10000);
    // Unref so the timer doesn't keep the process alive
    forceExitTimeout.unref();

    try {
      // 1. Close HTTP server (stop accepting new requests)
      await new Promise<void>((resolve, reject) => {
        server.close((err) => {
          if (err) {
            Logger.error("Error closing HTTP server", err);
            reject(err);
          } else {
            Logger.info("HTTP server closed successfully.");
            resolve();
          }
        });
      });

      // 2. Close Database Connection Pool
      if (AppDataSource.isInitialized) {
        await AppDataSource.destroy();
        Logger.info("Database connection closed successfully.");
      }

      Logger.info("Graceful shutdown complete.");
      process.exit(0);
    } catch (err) {
      Logger.error("Error during graceful shutdown", err);
      process.exit(1);
    }
  };

  process.on("SIGTERM", () => shutdown("SIGTERM"));
  process.on("SIGINT", () => shutdown("SIGINT"));

  process.on("uncaughtException", (error) => {
    Logger.error(`Uncaught exception: ${error.message}`, error);
    shutdown("uncaughtException");
  });

  process.on("unhandledRejection", (reason) => {
    const error = reason instanceof Error ? reason : new Error(String(reason));
    Logger.error(`Unhandled rejection: ${error.message}`, error);
    shutdown("unhandledRejection");
  });
}
