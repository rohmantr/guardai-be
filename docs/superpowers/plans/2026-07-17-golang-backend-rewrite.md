# Golang Backend Rewrite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rewrite the Rug Radar backend from TypeScript/TypeORM to Golang (inside `/backend`), preserving database migrations, structured logging, global error handling, and graceful shutdown, and update project configs (Makefile, Docker, compose files) accordingly.

**Architecture:** A lightweight Go application using the `net/http` standard library router, `jackc/pgx/v5` for PostgreSQL connection pooling, native `log/slog` for structured JSON logging, native signal handling for graceful shutdown, and an embedded migration runner using raw `.sql` files.

**Tech Stack:** Go 1.22+, `github.com/jackc/pgx/v5`, native `log/slog`.

## Global Constraints
- Target directory: `/backend`
- Connection pool: `pgxpool`
- Database Migrations: Embedded `.sql` migrations in transaction, tracked in table `go_migrations`
- Precision preservation: Balance fields must be represented as `string` in JSON APIs
- Code Quality: `go fmt` and `go test` must pass clean. No dead code.

---

### Task 1: Initialize Module & Config

**Files:**
- Create: `backend/go.mod`
- Create: `backend/config/config.go`

**Interfaces:**
- Produces: `config.LoadConfig() (*config.Config, error)` returning host, port, db url, log level.

- [ ] **Step 1: Create `backend/go.mod`**
- [ ] **Step 2: Create `backend/config/config.go` with env parsing**
- [ ] **Step 3: Add `go.sum` dependencies via `go get github.com/jackc/pgx/v5`**

---

### Task 2: Models & Precision Preservation

**Files:**
- Create: `backend/models/models.go`

- [ ] **Step 1: Create structs for `Token`, `RiskAssessment`, `PredictionPool`, `Position`, `ResolutionEvent`, `Attestation` using correct JSON and DB tags. Ensure balance fields like `amount`, `yes_pool_amount`, `no_pool_amount` are mapped as `string`.**

---

### Task 3: Database & Embed Migrations

**Files:**
- Create: `backend/db/db.go`
- Create: `backend/db/migrations.go`
- Create: `backend/db/migrations/*.sql` (copying the 6 .sql files from `src/migrations/`)

**Interfaces:**
- Produces: `db.Connect(url string) (*pgxpool.Pool, error)`
- Produces: `db.RunMigrations(pool *pgxpool.Pool) error`

- [ ] **Step 1: Copy migration SQL files into `backend/db/migrations/`**
- [ ] **Step 2: Write `db.go` setting up `pgxpool`**
- [ ] **Step 3: Write `migrations.go` using `go:embed` to read and execute SQL in order, tracking in a `go_migrations` table.**

---

### Task 4: Structured Logger & Middlewares

**Files:**
- Create: `backend/errors/errors.go`
- Create: `backend/middleware/logger.go`
- Create: `backend/middleware/recovery.go`

**Interfaces:**
- Produces: `middleware.RequestLogger(next http.Handler) http.Handler`
- Produces: `middleware.Recovery(next http.Handler) http.Handler`
- Produces: `errors.AppError` struct for custom API errors.

- [ ] **Step 1: Create `backend/errors/errors.go`**
- [ ] **Step 2: Create `backend/middleware/logger.go` using `log/slog`**
- [ ] **Step 3: Create `backend/middleware/recovery.go` to intercept panics and return JSON error payloads.**

---

### Task 5: Server Entrypoint & Graceful Shutdown

**Files:**
- Create: `backend/main.go`

- [ ] **Step 1: Create `main.go` implementing router `ServeMux`, `/health` endpoint, error-test endpoint, database initialization, and graceful shutdown signal interception.**

---

### Task 6: Tests & Integration Verification

**Files:**
- Create: `backend/test/database_test.go`

- [ ] **Step 1: Write integration tests in `backend/test/database_test.go` asserting pool creation, token insertions, and transactions.**
- [ ] **Step 2: Run `go test -v ./...` to verify all components work correctly.**

---

### Task 7: Infrastructure & Cleanup

**Files:**
- Modify: `Makefile`
- Modify: `Dockerfile`
- Modify: `docker-compose.local.yml`, `docker-compose.dev.yml`, `docker-compose.prod.yml`
- Delete: `src/` (recursively), `package.json`, `tsconfig.json`

- [ ] **Step 1: Update root `Makefile` targets to use Go CLI.**
- [ ] **Step 2: Rebuild `Dockerfile` with multi-stage Go build.**
- [ ] **Step 3: Update compose files to refer to the new backend build.**
- [ ] **Step 4: Delete the old TypeScript directory `src/` and configs.**
