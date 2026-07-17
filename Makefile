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
	be-dev be-build be-start be-test be-fmt

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

# --- Database Targets ---
db-up:
	docker compose -f $(COMPOSE_FILE) up -d

db-down:
	docker compose -f $(COMPOSE_FILE) down

db-logs:
	docker compose -f $(COMPOSE_FILE) logs -f postgres

db-migrate:
	DATABASE_URL=$(DATABASE_URL) bunx tsx ./node_modules/typeorm/cli.js migration:run -d src/common/database.ts

db-rollback:
	DATABASE_URL=$(DATABASE_URL) bunx tsx ./node_modules/typeorm/cli.js migration:revert -d src/common/database.ts

db-status:
	DATABASE_URL=$(DATABASE_URL) bunx tsx ./node_modules/typeorm/cli.js migration:show -d src/common/database.ts

# --- Backend Targets ---
be-dev:
	DATABASE_URL=$(DATABASE_URL) bun dev

be-build:
	bun run build

be-start:
	DATABASE_URL=$(DATABASE_URL) bun start

be-test:
	DATABASE_URL=$(DATABASE_URL) bun test src/

be-fmt:
	bun run fmt
