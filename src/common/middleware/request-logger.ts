import { Request, Response, NextFunction } from "express";
import { Logger } from "../utils/logger";

export function requestLogger(req: Request, res: Response, next: NextFunction) {
  const start = Date.now();
  res.on("finish", () => {
    const duration = Date.now() - start;
    Logger.info(
      `${req.method} ${req.url} - ${res.statusCode} (${duration}ms)`,
      {
        http_method: req.method,
        http_url: req.url,
        status_code: res.statusCode,
        duration_ms: duration,
        client_ip: req.ip,
      },
    );
  });
  next();
}
