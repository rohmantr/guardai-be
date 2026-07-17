# Specification: Golang Backend Rewrite

This specification outlines the rewrite of the Rug Radar backend service from TypeScript/TypeORM to Golang, located inside the `/backend` subfolder.

## 1. Architecture & Tech Stack

- **Language**: Go 1.22+
- **HTTP Server**: Native `net/http` standard library router (`http.NewServeMux`) with path/method matching.
- **Database Client**: `github.com/jackc/pgx/v5/pgxpool` for high-performance PostgreSQL connection pooling.
- **Structured Logging**: Native `log/slog` structured JSON logger (standard library).
- **Graceful Shutdown**: Native `os/signal` and `context` orchestration (standard library).
- **Database Migrations**: Go native migration runner reading raw SQL files embedded via `go:embed` and running them in a single SQL execution.

## 2. Directory Structure

```
backend/
├── go.mod
├── go.sum
├── main.go
├── config/
│   └── config.go
├── db/
│   ├── db.go
│   ├── migrations.go
│   └── migrations/
│       ├── 20260713000001-create-tokens.sql
│       ├── 20260713000002-create-risk-assessments.sql
│       ├── 20260713000003-create-prediction-pools.sql
│       ├── 20260713000004-create-positions.sql
│       ├── 20260713000005-create-resolution-events.sql
│       └── 20260713000006-create-attestations.sql
├── errors/
│   └── errors.go
├── middleware/
│   ├── logger.go
│   └── recovery.go
├── models/
│   └── models.go
└── test/
    └── database_test.go
```

## 3. Data Models & Precision Preservation

Columns representing large token balances (`yes_pool_amount`, `no_pool_amount`, `amount`) are represented as `string` in Go struct mappings (e.g., using `string` or `pgtype.Numeric` mapped as strings) to avoid precision loss when communicating over JSON.

Struct definitions include:
- `Token`
- `RiskAssessment`
- `PredictionPool`
- `Position`
- `ResolutionEvent`
- `Attestation`

## 4. Structured Logging (`log/slog`)

Using Go's native `log/slog`, logs are serialized as JSON:
```go
logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
    Level: logLevel,
}))
```

## 5. Global Error Handling & Recovery

A custom recovery middleware captures panic events, logs the stack trace using `slog.Error`, and returns a structured JSON error response:
```json
{
  "status": "error",
  "message": "Internal Server Error"
}
```
Custom API errors (`AppError`) bypass generalization and return their specific status code and error code.

## 6. Graceful Shutdown

- Intercepts `SIGINT` and `SIGTERM`.
- Closes the HTTP server listener first to reject new requests.
- Waits for active connections to drain.
- Closes the `pgxpool.Pool` database connection pool.
- Exits the process safely within a 10-second timeout.

## 7. Migration Mechanism

- SQL migrations are embedded directly inside the Go binary using `//go:embed db/migrations/*.sql`.
- On start, the app runs the migrations sequentially inside a transaction, recording run migrations in a metadata table `go_migrations` to prevent duplicate runs.

## 8. Development Environment (Makefile & Docker)

- Root `Makefile` targets (`db-migrate`, `be-dev`, `be-build`, `be-test`, `staging-*`, `prod-*`) updated to point to `/backend` commands.
- `Dockerfile` rebuilt with multi-stage Go build targeting alpine/scratch images.
