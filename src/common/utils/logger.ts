type LogLevel = "debug" | "info" | "warn" | "error";

const LEVEL_SEVERITY: Record<LogLevel, number> = {
  debug: 0,
  info: 1,
  warn: 2,
  error: 3,
};

const getLogLevel = (): LogLevel => {
  const envLevel = process.env.LOG_LEVEL?.toLowerCase();
  if (
    envLevel === "debug" ||
    envLevel === "info" ||
    envLevel === "warn" ||
    envLevel === "error"
  ) {
    return envLevel;
  }
  return "info";
};

const currentSeverity = LEVEL_SEVERITY[getLogLevel()];

export class Logger {
  private static log(
    level: LogLevel,
    message: string,
    context?: Record<string, any>,
  ) {
    if (LEVEL_SEVERITY[level] < currentSeverity) return;

    const payload = {
      level,
      message,
      timestamp: new Date().toISOString(),
      service: "guardai-be",
      ...context,
    };

    if (level === "error") {
      console.error(JSON.stringify(payload));
    } else {
      console.log(JSON.stringify(payload));
    }
  }

  static debug(message: string, context?: Record<string, any>) {
    this.log("debug", message, context);
  }

  static info(message: string, context?: Record<string, any>) {
    this.log("info", message, context);
  }

  static warn(message: string, context?: Record<string, any>) {
    this.log("warn", message, context);
  }

  static error(message: string, error?: any, context?: Record<string, any>) {
    let errorDetails: Record<string, any> = {};
    if (error instanceof Error) {
      errorDetails = {
        error_name: error.name,
        error_message: error.message,
        error_stack: error.stack,
      };
    } else if (error !== undefined) {
      errorDetails = { error: String(error) };
    }
    this.log("error", message, { ...errorDetails, ...context });
  }
}
