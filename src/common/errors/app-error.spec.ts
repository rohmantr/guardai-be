import { describe, expect, it } from "bun:test";
import { AppError } from "./app-error";

describe("AppError", () => {
  it("should construct an instance with statusCode, message, and code", () => {
    const error = new AppError(404, "Token not found", "TOKEN_NOT_FOUND");
    
    expect(error).toBeInstanceOf(Error);
    expect(error).toBeInstanceOf(AppError);
    expect(error.statusCode).toBe(404);
    expect(error.message).toBe("Token not found");
    expect(error.code).toBe("TOKEN_NOT_FOUND");
    expect(error.stack).toBeDefined();
  });
});
