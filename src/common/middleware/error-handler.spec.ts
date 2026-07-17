import { describe, expect, it, spyOn, afterEach } from "bun:test";
import { errorHandler } from "./error-handler";
import { Logger } from "../utils/logger";

describe("errorHandler", () => {
  const mockReq = {
    method: "POST",
    url: "/test-route",
    ip: "127.0.0.1",
  } as any;

  afterEach(() => {
    process.env.NODE_ENV = "test";
  });

  it("should return the error message and status code", () => {
    let responseStatus = 0;
    let responseJson: any = null;

    const mockRes = {
      status(code: number) {
        responseStatus = code;
        return this;
      },
      json(data: any) {
        responseJson = data;
        return this;
      },
    } as any;

    const testError = new Error("Bad request parameter");
    (testError as any).status = 400;

    const loggerSpy = spyOn(Logger, "error").mockImplementation(() => {});

    errorHandler(testError, mockReq, mockRes, () => {});

    expect(responseStatus).toBe(400);
    expect(responseJson).toEqual({
      status: "error",
      message: "Bad request parameter",
    });
    expect(loggerSpy).toHaveBeenCalled();

    loggerSpy.mockRestore();
  });

  it("should sanitize internal error messages (500) in production", () => {
    process.env.NODE_ENV = "production";
    let responseStatus = 0;
    let responseJson: any = null;

    const mockRes = {
      status(code: number) {
        responseStatus = code;
        return this;
      },
      json(data: any) {
        responseJson = data;
        return this;
      },
    } as any;

    const testError = new Error("Database crashed! Secret credentials: xxx");

    const loggerSpy = spyOn(Logger, "error").mockImplementation(() => {});

    errorHandler(testError, mockReq, mockRes, () => {});

    expect(responseStatus).toBe(500);
    expect(responseJson).toEqual({
      status: "error",
      message: "Internal Server Error",
    });
    expect(loggerSpy).toHaveBeenCalled();

    loggerSpy.mockRestore();
  });
});
