import { describe, expect, it, spyOn } from "bun:test";
import { requestLogger } from "./request-logger";
import { Logger } from "./logger";

describe("requestLogger", () => {
  it("should log request details on response finish", () => {
    const mockReq = {
      method: "GET",
      url: "/health",
      ip: "127.0.0.1",
    } as any;

    let finishCallback: Function = () => {};
    const mockRes = {
      statusCode: 200,
      on(event: string, callback: Function) {
        if (event === "finish") {
          finishCallback = callback;
        }
        return this;
      },
    } as any;

    const loggerSpy = spyOn(Logger, "info").mockImplementation(() => {});

    requestLogger(mockReq, mockRes, () => {});

    // Trigger finish event
    finishCallback();

    expect(loggerSpy).toHaveBeenCalled();
    const [message, context] = loggerSpy.mock.calls[0];
    expect(message).toContain("GET /health - 200");
    expect(context).toEqual(
      expect.objectContaining({
        http_method: "GET",
        http_url: "/health",
        status_code: 200,
        client_ip: "127.0.0.1",
      }),
    );

    loggerSpy.mockRestore();
  });
});
