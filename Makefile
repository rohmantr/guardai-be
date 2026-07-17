# Load environment variables from .env.local if it exists, fallback to .env
ifneq (,$(wildcard .env.local))
    include .env.local
    export
else ifneq (,$(wildcard .env))
    include .env
    export
endif

# Database & Docker Configuration Fallbacks
DATABASE_URL ?= postgresql://dev:dev@localhost:5432/rugradar_dev
COMPOSE_FILE ?= docker-compose.local.yml

.PHONY: build test test-all test-pp test-tr fmt check clean coverage \
	db-up db-down db-logs db-migrate db-rollback db-status \
	be-dev be-build be-start be-test be-fmt \
	staging-up staging-down staging-logs staging-migrate staging-rollback staging-status \
	prod-up prod-down prod-logs prod-migrate prod-rollback prod-status

# --- Smart Contract Targets ---
build:
	cd contracts && forge build

test: test-all
test-all:
	cd contracts && forge test

test-pp:
	cd contracts && forge test --match-path test/PredictionPool.t.sol -vvv

test-tr:
	cd contracts && forge test --match-path test/Treasury.t.sol -vvv

fmt:
	cd contracts && forge fmt

check:
	cd contracts && forge fmt --check

clean:
	cd contracts && forge clean

coverage:
	cd contracts && forge coverage --report lcov

# --- Database Targets (Local) ---
db-up:
	docker compose -f $(COMPOSE_FILE) up -d

db-down:
	docker compose -f $(COMPOSE_FILE) down

db-logs:
	docker compose -f $(COMPOSE_FILE) logs -f postgres

db-migrate:
	DATABASE_URL=$(DATABASE_URL) go -C backend run main.go -migrate-only

db-rollback:
	@echo "Rollback not supported for forward-only embedded migrations."

db-status:
	@echo "Migration status check not supported. Migrations run automatically on startup."

# --- Backend Targets (Local) ---
be-dev:
	DATABASE_URL=$(DATABASE_URL) go -C backend run main.go

be-build:
	go -C backend build -o bin/main main.go

be-start:
	DATABASE_URL=$(DATABASE_URL) ./backend/bin/main

be-test:
	DATABASE_URL=$(DATABASE_URL) go -C backend test -v ./...

be-fmt:
	go -C backend fmt ./...

# --- Staging / Dev Targets ---
staging-up:
	docker compose --env-file .env.dev -f docker-compose.dev.yml up -d

staging-down:
	docker compose --env-file .env.dev -f docker-compose.dev.yml down

staging-logs:
	docker compose --env-file .env.dev -f docker-compose.dev.yml logs -f backend

staging-migrate:
	@if [ ! -f .env.dev ]; then echo "Error: .env.dev file not found! Copy .env.dev.example first."; exit 1; fi; \
	DATABASE_URL=$$(grep -E "^DATABASE_URL=" .env.dev | cut -d '=' -f2-) go -C backend run main.go -migrate-only

staging-rollback:
	@echo "Rollback not supported for forward-only embedded migrations."

staging-status:
	@echo "Migration status check not supported. Migrations run automatically on startup."

# --- Production Targets ---
prod-up:
	docker compose --env-file .env.prod -f docker-compose.prod.yml up -d

prod-down:
	docker compose --env-file .env.prod -f docker-compose.prod.yml down

prod-logs:
	docker compose --env-file .env.prod -f docker-compose.prod.yml logs -f backend

prod-migrate:
	@if [ ! -f .env.prod ]; then echo "Error: .env.prod file not found! Copy .env.prod.example first."; exit 1; fi; \
	DATABASE_URL=$$(grep -E "^DATABASE_URL=" .env.prod | cut -d '=' -f2-) go -C backend run main.go -migrate-only

prod-rollback:
	@echo "Rollback not supported for forward-only embedded migrations."

prod-status:
	@echo "Migration status check not supported. Migrations run automatically on startup."
