# Database Schema and Migrations Design Spec

**Versi:** 1.0
**Tanggal:** 13 Juli 2026
**Terkait:** docs/specifications/database-schema.md, docs/architecture/database.md

---

## 1. Objective & Scope

Implement database schema, migrations, and TypeScript entities for the 6 core tables of Rug Radar:
1. `tokens`
2. `risk_assessments`
3. `prediction_pools`
4. `positions`
5. `resolution_events`
6. `attestations`

This database implementation uses PostgreSQL and TypeORM, configured with migrations running from raw SQL files.

---

## 2. Dependencies & Configurations

### TypeScript Configuration (`tsconfig.json`)
TypeORM requires metadata decorators. We will enable:
- `experimentalDecorators: true`
- `emitDecoratorMetadata: true`

### Dependencies
We need to install:
- `typeorm`
- `pg`
- `reflect-metadata`
And `@types/pg` as devDependency.

---

## 3. Database Connection Configuration (`src/common/database.ts`)

A central TypeORM `DataSource` configuration that:
- Reads from `DATABASE_URL` environment variable.
- Uses `postgres` driver.
- Configures connection pool settings (min/max connections, timeouts).
- Disables automatic schema synchronization in production.
- Registers entities located in `src/modules/*/entities/*.entity.ts`.
- Registers migrations in `src/migrations/*.ts` or `src/migrations/*.js`.

---

## 4. Entity Specifications

All schemas map 1-to-1 to `docs/specifications/database-schema.md` requirements.

### 4.1 Token Entity (`src/modules/token/entities/token.entity.ts`)
- `id`: Primary key, uuid.
- `address`: varchar(42), unique.
- `chain_id`: integer, defaults to 8453 (Base).
- `deployer`: varchar(42).
- `deployed_at`: timestamptz.
- `has_unlimited_mint`: boolean, nullable.
- `has_blacklist`: boolean, nullable.
- `has_tax`: boolean, nullable.
- `liquidity_locked`: boolean, nullable.
- `top_holder_concentration`: decimal(5, 4), nullable.
- `created_at`: timestamptz.
- `updated_at`: timestamptz.

### 4.2 Risk Assessment Entity (`src/modules/assessment/entities/risk-assessment.entity.ts`)
- `id`: Primary key, uuid.
- `token_id`: uuid (FK to `tokens.id` with `ON DELETE CASCADE`).
- `probability`: decimal(5, 4).
- `reasoning`: text.
- `confidence`: decimal(5, 4).
- `llm_model`: varchar(50).
- `assessed_at`: timestamptz.
- `created_at`: timestamptz.

### 4.3 Prediction Pool Entity (`src/modules/prediction/entities/prediction-pool.entity.ts`)
- `id`: Primary key, uuid.
- `token_id`: uuid (FK to `tokens.id` with `ON DELETE CASCADE`).
- `assessment_id`: uuid (FK to `risk_assessments.id` with `ON DELETE RESTRICT`).
- `contract_address`: varchar(42), unique.
- `yes_pool_amount`: numeric(40, 0) (stored as `string` in TS).
- `no_pool_amount`: numeric(40, 0) (stored as `string` in TS).
- `status`: varchar(20) (active, resolved, expired).
- `deadline`: timestamptz.
- `created_at`: timestamptz.
- `resolved_at`: timestamptz, nullable.

### 4.4 Position Entity (`src/modules/prediction/entities/position.entity.ts`)
- `id`: Primary key, uuid.
- `pool_id`: uuid (FK to `prediction_pools.id` with `ON DELETE CASCADE`).
- `user_address`: varchar(42).
- `side`: varchar(3) (YES, NO).
- `amount`: numeric(40, 0) (stored as `string` in TS).
- `claimed`: boolean, defaults to false.
- `created_at`: timestamptz.
- Unique index on `(pool_id, user_address)`.

### 4.5 Resolution Event Entity (`src/modules/oracle/entities/resolution-event.entity.ts`)
- `id`: Primary key, uuid.
- `pool_id`: uuid (FK to `prediction_pools.id` with `ON DELETE CASCADE`, unique).
- `liquidity_pulled`: boolean.
- `winning_side`: varchar(3) (YES, NO).
- `tx_hash`: varchar(66).
- `resolved_at`: timestamptz.

### 4.6 Attestation Entity (`src/modules/attestation/entities/attestation.entity.ts`)
- `id`: Primary key, uuid.
- `pool_id`: uuid (FK to `resolution_events.pool_id` with `ON DELETE CASCADE`, unique).
- `eas_uid`: varchar(66), unique.
- `predicted_outcome`: boolean.
- `actual_outcome`: boolean.
- `attested_at`: timestamptz.

---

## 5. Migration Execution Strategy

We will maintain SQL files at `src/migrations/*.sql` and companion TypeScript files `src/migrations/*.ts` that read the SQL files and execute them.

Example companion ts migration:
```typescript
import { MigrationInterface, QueryRunner } from "typeorm";
import * as fs from "fs";
import * as path from "path";

export class CreateTokens20260713000001 implements MigrationInterface {
    public async up(queryRunner: QueryRunner): Promise<void> {
        const sqlPath = path.join(__dirname, "20260713000001-create-tokens.sql");
        const sql = fs.readFileSync(sqlPath, "utf8");
        await queryRunner.query(sql);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`DROP TABLE IF EXISTS "tokens" CASCADE;`);
    }
}
```

---

## 6. Testing Strategy
- Create a test file `src/common/database.spec.ts` using Vitest.
- Run postgres container using docker compose.
- Test initialization, migration execution, insertion, and retrieval for each of the 6 entities.
- Verify that constraints (e.g. check constraints on side/status, cascades, foreign keys) behave as expected.
