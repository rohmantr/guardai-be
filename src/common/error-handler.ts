import { Request, Response, NextFunction } from "express";
import { Logger } from "./logger";

export function errorHandler(
  err: any,
  req: Request,
  res: Response,
  _next: NextFunction,
) {
  const status = err.status || err.statusCode || 500;
  const isProduction = process.env.NODE_ENV === "production";

  // Hide detailed internal server error messages in production for security
  const message =
    isProduction && status === 500
      ? "Internal Server Error"
      : err.message || "An unexpected error occurred";

  Logger.error(`Request failed: ${req.method} ${req.url}`, err, {
    http_method: req.method,
    http_url: req.url,
    client_ip: req.ip,
    status_code: status,
  });

  res.status(status).json({
    status: "error",
    message,
    ...(err.code ? { code: err.code } : {}),
  });
}
