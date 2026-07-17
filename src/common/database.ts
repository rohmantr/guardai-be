import "reflect-metadata";
import { DataSource } from "typeorm";
import * as path from "path";

const dbUrl =
  process.env.DATABASE_URL ??
  "postgresql://dev:dev@localhost:5432/rugradar_dev";

export const AppDataSource = new DataSource({
  type: "postgres",
  url: dbUrl,
  synchronize: false,
  logging: process.env.LOG_LEVEL === "debug",
  entities: [path.join(__dirname, "../modules/*/entities/*.entity.{ts,js}")],
  migrations: [path.join(__dirname, "../migrations/*.{ts,js}")],
  extra: {
    min: process.env.NODE_ENV === "production" ? 5 : 2,
    max: process.env.NODE_ENV === "production" ? 25 : 10,
    idleTimeoutMillis: process.env.NODE_ENV === "production" ? 60000 : 30000,
    connectionTimeoutMillis:
      process.env.NODE_ENV === "production" ? 10000 : 5000,
  },
});
