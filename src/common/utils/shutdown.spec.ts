import { describe, expect, it, spyOn } from "bun:test";
import { setupGracefulShutdown } from "./shutdown";
import { AppDataSource } from "../database";

describe("setupGracefulShutdown", () => {
  it("should trigger shutdown and close server/db on signal", async () => {
    let serverClosed = false;
    const mockServer = {
      close(callback: (err?: Error) => void) {
        serverClosed = true;
        callback();
        return this;
      },
    } as any;

    // Ensure AppDataSource is mock-initialized
    const originalIsInitialized = AppDataSource.isInitialized;
    Object.defineProperty(AppDataSource, "isInitialized", {
      value: true,
      writable: true,
    });

    const dbDestroySpy = spyOn(AppDataSource, "destroy").mockImplementation(
      async () => {},
    );
    const exitSpy = spyOn(process, "exit").mockImplementation(
      (code?: number): never => {
        throw new Error(`Exit called with ${code}`);
      },
    );

    // Temporarily intercept process.on
    const listeners: Record<string, Function> = {};
    const originalOn = process.on;
    (process.on as any) = (event: string, callback: any): any => {
      listeners[event] = callback;
      return process;
    };

    setupGracefulShutdown(mockServer);

    // Verify listeners are registered
    expect(listeners["SIGTERM"]).toBeDefined();
    expect(listeners["SIGINT"]).toBeDefined();
    expect(listeners["uncaughtException"]).toBeDefined();
    expect(listeners["unhandledRejection"]).toBeDefined();

    // Trigger the mock SIGTERM listener
    try {
      await listeners["SIGTERM"]();
    } catch (e) {
      // Catch mock exit exception
    }

    expect(serverClosed).toBe(true);
    expect(dbDestroySpy).toHaveBeenCalled();
    expect(exitSpy).toHaveBeenCalledWith(0);

    // Restore original functions
    process.on = originalOn;
    dbDestroySpy.mockRestore();
    exitSpy.mockRestore();
    Object.defineProperty(AppDataSource, "isInitialized", {
      value: originalIsInitialized,
      writable: true,
    });
  });
});
