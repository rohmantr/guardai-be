import { describe, expect, it, spyOn } from "bun:test";
import { Logger } from "./logger";

describe("Logger", () => {
  it("should output structured JSON format for info logs", () => {
    const logSpy = spyOn(console, "log");
    Logger.info("Test message", { key: "value" });

    expect(logSpy).toHaveBeenCalled();
    const output = JSON.parse(logSpy.mock.calls[0][0]);
    expect(output.level).toBe("info");
    expect(output.message).toBe("Test message");
    expect(output.key).toBe("value");
    expect(output.service).toBe("guardai-be");
    expect(output.timestamp).toBeDefined();

    logSpy.mockRestore();
  });

  it("should output structured JSON format for error logs with error details", () => {
    const errorSpy = spyOn(console, "error");
    const testError = new Error("Something went wrong");
    Logger.error("Error occurred", testError, { contextId: "123" });

    expect(errorSpy).toHaveBeenCalled();
    const output = JSON.parse(errorSpy.mock.calls[0][0]);
    expect(output.level).toBe("error");
    expect(output.message).toBe("Error occurred");
    expect(output.error_name).toBe("Error");
    expect(output.error_message).toBe("Something went wrong");
    expect(output.error_stack).toBeDefined();
    expect(output.contextId).toBe("123");

    errorSpy.mockRestore();
  });
});
