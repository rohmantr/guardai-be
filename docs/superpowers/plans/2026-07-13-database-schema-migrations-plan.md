# Database Schema and Migrations Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement PostgreSQL database schema, raw SQL migrations with TypeORM companion runners, DataSource connection helper, and TypeORM entities representing the Rug Radar database schema, then verify them with a suite of integration tests.

**Architecture:** PostgreSQL 16 database accessed via TypeORM `DataSource`. SQL migrations are executed by companion TypeScript migrations. TypeORM entities define relations, types, and indexes conforming to the schema specification.

**Tech Stack:** TypeScript, Bun, TypeORM, PG (node-postgres), Vitest.

## Global Constraints

- Database: PostgreSQL (schema must map 1-to-1 to `docs/specifications/database-schema.md` requirements).
- Numeric precision: large numbers representing wei values (amount, pools) stored as `numeric(40, 0)` in SQL and `string` in TypeScript to prevent precision loss.
- TS Decorators: enabled in tsconfig.json.
- Migrations: raw SQL in `src/migrations/*.sql` run by companion `.ts` migration classes.

---

### Task 1: Environment & Setup Configuration

**Files:**
- Modify: `tsconfig.json`
- Modify: `package.json`

**Interfaces:**
- Produces: Installed dependencies `typeorm`, `pg`, `reflect-metadata`, and `@types/pg` devDependency, plus decorated support enabled.

- [ ] **Step 1: Edit `package.json` to add database dependencies**
      Modify package.json to include the required packages.
- [ ] **Step 2: Run `bun install` to download dependencies**
      Run `bun install` using bash.
- [ ] **Step 3: Edit `tsconfig.json` to enable decorator support**
      Add `"experimentalDecorators": true` and `"emitDecoratorMetadata": true` to compilerOptions.
- [ ] **Step 4: Verify project build compiles**
      Run: `bun run build`
      Expected: compiles without errors.
- [ ] **Step 5: Commit changes**
      Run: `git add package.json tsconfig.json bun.lock && git commit -m "chore: setup database dependencies and tsconfig decorators"`

---

### Task 2: Database Connection & DataSource Configuration

**Files:**
- Create: `src/common/database.ts`

**Interfaces:**
- Produces: Exported `AppDataSource` instance of TypeORM `DataSource`.

- [ ] **Step 1: Create `src/common/database.ts`**
      Implement the DataSource initialization code using PostgreSQL, parsing `DATABASE_URL` environment variable, setting connection pooling limits, and pointing to entity and migration directories.
      Use this code:
```typescript
import "reflect-metadata";
import { DataSource } from "typeorm";
import * as path from "path";

const dbUrl = process.env.DATABASE_URL ?? "postgresql://dev:dev@localhost:5432/rugradar_dev";

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
        connectionTimeoutMillis: process.env.NODE_ENV === "production" ? 10000 : 5000,
    }
});
```
- [ ] **Step 2: Run build to ensure compile success**
      Run: `bun run build`
      Expected: Compiles with no errors.
- [ ] **Step 3: Commit**
      Run: `git add src/common/database.ts && git commit -m "feat(backend): configure database connection datasource"`

---

### Task 3: SQL Migration Files Creation

**Files:**
- Create: `src/migrations/20260713000001-create-tokens.sql`
- Create: `src/migrations/20260713000002-create-risk-assessments.sql`
- Create: `src/migrations/20260713000003-create-prediction-pools.sql`
- Create: `src/migrations/20260713000004-create-positions.sql`
- Create: `src/migrations/20260713000005-create-resolution-events.sql`
- Create: `src/migrations/20260713000006-create-attestations.sql`

- [ ] **Step 1: Create `src/migrations/20260713000001-create-tokens.sql`**
```sql
CREATE TABLE IF NOT EXISTS tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    address VARCHAR(42) NOT NULL UNIQUE,
    chain_id INTEGER NOT NULL DEFAULT 8453,
    deployer VARCHAR(42) NOT NULL,
    deployed_at TIMESTAMPTZ NOT NULL,
    has_unlimited_mint BOOLEAN DEFAULT NULL,
    has_blacklist BOOLEAN DEFAULT NULL,
    has_tax BOOLEAN DEFAULT NULL,
    liquidity_locked BOOLEAN DEFAULT NULL,
    top_holder_concentration DECIMAL(5,4) DEFAULT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_tokens_address_chain_id ON tokens (chain_id, address);
CREATE INDEX IF NOT EXISTS idx_tokens_deployed_at_desc ON tokens (deployed_at DESC);
```
- [ ] **Step 2: Create `src/migrations/20260713000002-create-risk-assessments.sql`**
```sql
CREATE TABLE IF NOT EXISTS risk_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token_id UUID NOT NULL REFERENCES tokens(id) ON DELETE CASCADE,
    probability DECIMAL(5,4) NOT NULL,
    reasoning TEXT NOT NULL,
    confidence DECIMAL(5,4) NOT NULL,
    llm_model VARCHAR(50) NOT NULL,
    assessed_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_risk_assessments_token_id ON risk_assessments (token_id);
CREATE INDEX IF NOT EXISTS idx_risk_assessments_token_id_assessed_at ON risk_assessments (token_id, assessed_at DESC);
```
- [ ] **Step 3: Create `src/migrations/20260713000003-create-prediction-pools.sql`**
```sql
CREATE TABLE IF NOT EXISTS prediction_pools (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token_id UUID NOT NULL REFERENCES tokens(id) ON DELETE CASCADE,
    assessment_id UUID NOT NULL REFERENCES risk_assessments(id) ON DELETE RESTRICT,
    contract_address VARCHAR(42) NOT NULL UNIQUE,
    yes_pool_amount NUMERIC(40,0) NOT NULL DEFAULT 0,
    no_pool_amount NUMERIC(40,0) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'resolved', 'expired')),
    deadline TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_at TIMESTAMPTZ DEFAULT NULL
);

CREATE INDEX IF NOT EXISTS idx_prediction_pools_token_id ON prediction_pools (token_id);
CREATE INDEX IF NOT EXISTS idx_prediction_pools_status ON prediction_pools (status);
CREATE INDEX IF NOT EXISTS idx_prediction_pools_deadline ON prediction_pools (deadline);
```
- [ ] **Step 4: Create `src/migrations/20260713000004-create-positions.sql`**
```sql
CREATE TABLE IF NOT EXISTS positions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pool_id UUID NOT NULL REFERENCES prediction_pools(id) ON DELETE CASCADE,
    user_address VARCHAR(42) NOT NULL,
    side VARCHAR(3) NOT NULL CHECK (side IN ('YES', 'NO')),
    amount NUMERIC(40,0) NOT NULL CHECK (amount > 0),
    claimed BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_positions_pool_id_user_address ON positions (pool_id, user_address);
CREATE INDEX IF NOT EXISTS idx_positions_user_address ON positions (user_address);
CREATE INDEX IF NOT EXISTS idx_positions_pool_id ON positions (pool_id);
```
- [ ] **Step 5: Create `src/migrations/20260713000005-create-resolution-events.sql`**
```sql
CREATE TABLE IF NOT EXISTS resolution_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pool_id UUID NOT NULL UNIQUE REFERENCES prediction_pools(id) ON DELETE CASCADE,
    liquidity_pulled BOOLEAN NOT NULL,
    winning_side VARCHAR(3) NOT NULL CHECK (winning_side IN ('YES', 'NO')),
    tx_hash VARCHAR(66) NOT NULL,
    resolved_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```
- [ ] **Step 6: Create `src/migrations/20260713000006-create-attestations.sql`**
```sql
CREATE TABLE IF NOT EXISTS attestations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pool_id UUID NOT NULL UNIQUE REFERENCES resolution_events(pool_id) ON DELETE CASCADE,
    eas_uid VARCHAR(66) NOT NULL UNIQUE,
    predicted_outcome BOOLEAN NOT NULL,
    actual_outcome BOOLEAN NOT NULL,
    attested_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```
- [ ] **Step 7: Commit**
      Run: `git add src/migrations/*.sql && git commit -m "feat(backend): add raw SQL migration files"`

---

### Task 4: Companion TS Migration Classes

**Files:**
- Create: `src/migrations/20260713000001-create-tokens.ts`
- Create: `src/migrations/20260713000002-create-risk-assessments.ts`
- Create: `src/migrations/20260713000003-create-prediction-pools.ts`
- Create: `src/migrations/20260713000004-create-positions.ts`
- Create: `src/migrations/20260713000005-create-resolution-events.ts`
- Create: `src/migrations/20260713000006-create-attestations.ts`

- [ ] **Step 1: Create TS companion for Tokens migration**
```typescript
import { MigrationInterface, QueryRunner } from "typeorm";
import * as fs from "fs";
import * as path from "path";

export class CreateTokens20260713000001 implements MigrationInterface {
    name = 'CreateTokens20260713000001';

    public async up(queryRunner: QueryRunner): Promise<void> {
        const sql = fs.readFileSync(path.join(__dirname, "20260713000001-create-tokens.sql"), "utf8");
        await queryRunner.query(sql);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`DROP TABLE IF EXISTS tokens CASCADE;`);
    }
}
```
- [ ] **Step 2: Create TS companion for Risk Assessments migration**
```typescript
import { MigrationInterface, QueryRunner } from "typeorm";
import * as fs from "fs";
import * as path from "path";

export class CreateRiskAssessments20260713000002 implements MigrationInterface {
    name = 'CreateRiskAssessments20260713000002';

    public async up(queryRunner: QueryRunner): Promise<void> {
        const sql = fs.readFileSync(path.join(__dirname, "20260713000002-create-risk-assessments.sql"), "utf8");
        await queryRunner.query(sql);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`DROP TABLE IF EXISTS risk_assessments CASCADE;`);
    }
}
```
- [ ] **Step 3: Create TS companion for Prediction Pools migration**
```typescript
import { MigrationInterface, QueryRunner } from "typeorm";
import * as fs from "fs";
import * as path from "path";

export class CreatePredictionPools20260713000003 implements MigrationInterface {
    name = 'CreatePredictionPools20260713000003';

    public async up(queryRunner: QueryRunner): Promise<void> {
        const sql = fs.readFileSync(path.join(__dirname, "20260713000003-create-prediction-pools.sql"), "utf8");
        await queryRunner.query(sql);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`DROP TABLE IF EXISTS prediction_pools CASCADE;`);
    }
}
```
- [ ] **Step 4: Create TS companion for Positions migration**
```typescript
import { MigrationInterface, QueryRunner } from "typeorm";
import * as fs from "fs";
import * as path from "path";

export class CreatePositions20260713000004 implements MigrationInterface {
    name = 'CreatePositions20260713000004';

    public async up(queryRunner: QueryRunner): Promise<void> {
        const sql = fs.readFileSync(path.join(__dirname, "20260713000004-create-positions.sql"), "utf8");
        await queryRunner.query(sql);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`DROP TABLE IF EXISTS positions CASCADE;`);
    }
}
```
- [ ] **Step 5: Create TS companion for Resolution Events migration**
```typescript
import { MigrationInterface, QueryRunner } from "typeorm";
import * as fs from "fs";
import * as path from "path";

export class CreateResolutionEvents20260713000005 implements MigrationInterface {
    name = 'CreateResolutionEvents20260713000005';

    public async up(queryRunner: QueryRunner): Promise<void> {
        const sql = fs.readFileSync(path.join(__dirname, "20260713000005-create-resolution-events.sql"), "utf8");
        await queryRunner.query(sql);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`DROP TABLE IF EXISTS resolution_events CASCADE;`);
    }
}
```
- [ ] **Step 6: Create TS companion for Attestations migration**
```typescript
import { MigrationInterface, QueryRunner } from "typeorm";
import * as fs from "fs";
import * as path from "path";

export class CreateAttestations20260713000006 implements MigrationInterface {
    name = 'CreateAttestations20260713000006';

    public async up(queryRunner: QueryRunner): Promise<void> {
        const sql = fs.readFileSync(path.join(__dirname, "20260713000006-create-attestations.sql"), "utf8");
        await queryRunner.query(sql);
    }

    public async down(queryRunner: QueryRunner): Promise<void> {
        await queryRunner.query(`DROP TABLE IF EXISTS attestations CASCADE;`);
    }
}
```
- [ ] **Step 7: Commit**
      Run: `git add src/migrations/*.ts && git commit -m "feat(backend): add TS migration classes"`

---

### Task 5: TypeScript Entities Implementation

**Files:**
- Create: `src/modules/token/entities/token.entity.ts`
- Create: `src/modules/assessment/entities/risk-assessment.entity.ts`
- Create: `src/modules/prediction/entities/prediction-pool.entity.ts`
- Create: `src/modules/prediction/entities/position.entity.ts`
- Create: `src/modules/oracle/entities/resolution-event.entity.ts`
- Create: `src/modules/attestation/entities/attestation.entity.ts`

- [ ] **Step 1: Create `src/modules/token/entities/token.entity.ts`**
```typescript
import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, OneToMany } from "typeorm";
import { RiskAssessment } from "../../assessment/entities/risk-assessment.entity";
import { PredictionPool } from "../../prediction/entities/prediction-pool.entity";

@Entity({ name: "tokens" })
export class Token {
    @PrimaryGeneratedColumn("uuid")
    id!: string;

    @Column({ type: "varchar", length: 42, unique: true })
    address!: string;

    @Column({ type: "integer", name: "chain_id", default: 8453 })
    chainId!: number;

    @Column({ type: "varchar", length: 42 })
    deployer!: string;

    @Column({ type: "timestamptz", name: "deployed_at" })
    deployedAt!: Date;

    @Column({ type: "boolean", name: "has_unlimited_mint", nullable: true })
    hasUnlimitedMint!: boolean | null;

    @Column({ type: "boolean", name: "has_blacklist", nullable: true })
    hasBlacklist!: boolean | null;

    @Column({ type: "boolean", name: "has_tax", nullable: true })
    hasTax!: boolean | null;

    @Column({ type: "boolean", name: "liquidity_locked", nullable: true })
    liquidityLocked!: boolean | null;

    @Column({ type: "decimal", precision: 5, scale: 4, name: "top_holder_concentration", nullable: true })
    topHolderConcentration!: number | null;

    @CreateDateColumn({ type: "timestamptz", name: "created_at" })
    createdAt!: Date;

    @UpdateDateColumn({ type: "timestamptz", name: "updated_at" })
    updatedAt!: Date;

    @OneToMany(() => RiskAssessment, (assessment) => assessment.token)
    assessments!: RiskAssessment[];

    @OneToMany(() => PredictionPool, (pool) => pool.token)
    pools!: PredictionPool[];
}
```
- [ ] **Step 2: Create `src/modules/assessment/entities/risk-assessment.entity.ts`**
```typescript
import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn, OneToMany } from "typeorm";
import { Token } from "../../token/entities/token.entity";
import { PredictionPool } from "../../prediction/entities/prediction-pool.entity";

@Entity({ name: "risk_assessments" })
export class RiskAssessment {
    @PrimaryGeneratedColumn("uuid")
    id!: string;

    @Column({ type: "uuid", name: "token_id" })
    tokenId!: string;

    @ManyToOne(() => Token, (token) => token.assessments, { onDelete: "CASCADE" })
    @JoinColumn({ name: "token_id" })
    token!: Token;

    @Column({ type: "decimal", precision: 5, scale: 4 })
    probability!: number;

    @Column({ type: "text" })
    reasoning!: string;

    @Column({ type: "decimal", precision: 5, scale: 4 })
    confidence!: number;

    @Column({ type: "varchar", length: 50, name: "llm_model" })
    llmModel!: string;

    @Column({ type: "timestamptz", name: "assessed_at" })
    assessedAt!: Date;

    @CreateDateColumn({ type: "timestamptz", name: "created_at" })
    createdAt!: Date;

    @OneToMany(() => PredictionPool, (pool) => pool.assessment)
    pools!: PredictionPool[];
}
```
- [ ] **Step 3: Create `src/modules/prediction/entities/prediction-pool.entity.ts`**
```typescript
import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn, OneToMany, OneToOne } from "typeorm";
import { Token } from "../../token/entities/token.entity";
import { RiskAssessment } from "../../assessment/entities/risk-assessment.entity";
import { Position } from "./position.entity";
import { ResolutionEvent } from "../../oracle/entities/resolution-event.entity";

@Entity({ name: "prediction_pools" })
export class PredictionPool {
    @PrimaryGeneratedColumn("uuid")
    id!: string;

    @Column({ type: "uuid", name: "token_id" })
    tokenId!: string;

    @ManyToOne(() => Token, (token) => token.pools, { onDelete: "CASCADE" })
    @JoinColumn({ name: "token_id" })
    token!: Token;

    @Column({ type: "uuid", name: "assessment_id" })
    assessmentId!: string;

    @ManyToOne(() => RiskAssessment, (assessment) => assessment.pools, { onDelete: "RESTRICT" })
    @JoinColumn({ name: "assessment_id" })
    assessment!: RiskAssessment;

    @Column({ type: "varchar", length: 42, unique: true, name: "contract_address" })
    contractAddress!: string;

    @Column({ type: "numeric", precision: 40, scale: 0, name: "yes_pool_amount", default: "0" })
    yesPoolAmount!: string;

    @Column({ type: "numeric", precision: 40, scale: 0, name: "no_pool_amount", default: "0" })
    noPoolAmount!: string;

    @Column({ type: "varchar", length: 20, default: "active" })
    status!: "active" | "resolved" | "expired";

    @Column({ type: "timestamptz" })
    deadline!: Date;

    @CreateDateColumn({ type: "timestamptz", name: "created_at" })
    createdAt!: Date;

    @Column({ type: "timestamptz", name: "resolved_at", nullable: true })
    resolvedAt!: Date | null;

    @OneToMany(() => Position, (position) => position.pool)
    positions!: Position[];

    @OneToOne(() => ResolutionEvent, (event) => event.pool)
    resolutionEvent!: ResolutionEvent;
}
```
- [ ] **Step 4: Create `src/modules/prediction/entities/position.entity.ts`**
```typescript
import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from "typeorm";
import { PredictionPool } from "./prediction-pool.entity";

@Entity({ name: "positions" })
export class Position {
    @PrimaryGeneratedColumn("uuid")
    id!: string;

    @Column({ type: "uuid", name: "pool_id" })
    poolId!: string;

    @ManyToOne(() => PredictionPool, (pool) => pool.positions, { onDelete: "CASCADE" })
    @JoinColumn({ name: "pool_id" })
    pool!: PredictionPool;

    @Column({ type: "varchar", length: 42, name: "user_address" })
    userAddress!: string;

    @Column({ type: "varchar", length: 3 })
    side!: "YES" | "NO";

    @Column({ type: "numeric", precision: 40, scale: 0 })
    amount!: string;

    @Column({ type: "boolean", default: false })
    claimed!: boolean;

    @CreateDateColumn({ type: "timestamptz", name: "created_at" })
    createdAt!: Date;
}
```
- [ ] **Step 5: Create `src/modules/oracle/entities/resolution-event.entity.ts`**
```typescript
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, OneToOne } from "typeorm";
import { PredictionPool } from "../../prediction/entities/prediction-pool.entity";
import { Attestation } from "../../attestation/entities/attestation.entity";

@Entity({ name: "resolution_events" })
export class ResolutionEvent {
    @PrimaryGeneratedColumn("uuid")
    id!: string;

    @Column({ type: "uuid", name: "pool_id", unique: true })
    poolId!: string;

    @OneToOne(() => PredictionPool, (pool) => pool.resolutionEvent, { onDelete: "CASCADE" })
    @JoinColumn({ name: "pool_id" })
    pool!: PredictionPool;

    @Column({ type: "boolean", name: "liquidity_pulled" })
    liquidityPulled!: boolean;

    @Column({ type: "varchar", length: 3, name: "winning_side" })
    winningSide!: "YES" | "NO";

    @Column({ type: "varchar", length: 66, name: "tx_hash" })
    txHash!: string;

    @Column({ type: "timestamptz", name: "resolved_at", default: () => "CURRENT_TIMESTAMP" })
    resolvedAt!: Date;

    @OneToOne(() => Attestation, (attestation) => attestation.resolutionEvent)
    attestation!: Attestation;
}
```
- [ ] **Step 6: Create `src/modules/attestation/entities/attestation.entity.ts`**
```typescript
import { Entity, PrimaryGeneratedColumn, Column, OneToOne, JoinColumn } from "typeorm";
import { ResolutionEvent } from "../../oracle/entities/resolution-event.entity";

@Entity({ name: "attestations" })
export class Attestation {
    @PrimaryGeneratedColumn("uuid")
    id!: string;

    @Column({ type: "uuid", name: "pool_id", unique: true })
    poolId!: string;

    @OneToOne(() => ResolutionEvent, (event) => event.attestation, { onDelete: "CASCADE" })
    @JoinColumn({ name: "pool_id", referencedColumnName: "poolId" })
    resolutionEvent!: ResolutionEvent;

    @Column({ type: "varchar", length: 66, unique: true, name: "eas_uid" })
    easUid!: string;

    @Column({ type: "boolean", name: "predicted_outcome" })
    predictedOutcome!: boolean;

    @Column({ type: "boolean", name: "actual_outcome" })
    actualOutcome!: boolean;

    @Column({ type: "timestamptz", name: "attested_at", default: () => "CURRENT_TIMESTAMP" })
    attestedAt!: Date;
}
```
- [ ] **Step 7: Verify project compilation passes**
      Run: `bun run build`
      Expected: successfully builds.
- [ ] **Step 8: Commit**
      Run: `git add src/modules/**/*.ts && git commit -m "feat(backend): implement TypeORM entities for all tables"`

---

### Task 6: Database Integration Testing

**Files:**
- Create: `src/common/database.spec.ts`

- [ ] **Step 1: Start postgres container in local environment**
      Run: `docker compose up -d postgres`
- [ ] **Step 2: Create `src/common/database.spec.ts` integration test**
      Write a comprehensive integration test that:
      1. Initializes `AppDataSource`.
      2. Executes all migrations (`runMigrations`).
      3. Performs insertions, queries, and verify relational behaviors/cascades on each entity.
      4. Tears down connections and rolls back / drops tables.
```typescript
import { describe, it, beforeAll, afterAll, expect } from "vitest";
import { AppDataSource } from "./database";
import { Token } from "../modules/token/entities/token.entity";
import { RiskAssessment } from "../modules/assessment/entities/risk-assessment.entity";
import { PredictionPool } from "../modules/prediction/entities/prediction-pool.entity";
import { Position } from "../modules/prediction/entities/position.entity";
import { ResolutionEvent } from "../modules/oracle/entities/resolution-event.entity";
import { Attestation } from "../modules/attestation/entities/attestation.entity";

describe("Database Integration Tests", () => {
    beforeAll(async () => {
        // Initialize data source and run migrations
        if (!AppDataSource.isInitialized) {
            await AppDataSource.initialize();
        }
        await AppDataSource.runMigrations();
    });

    afterAll(async () => {
        if (AppDataSource.isInitialized) {
            // Revert migrations
            const migrations = [...AppDataSource.migrations].reverse();
            for (const migration of migrations) {
                await AppDataSource.undoLastMigration();
            }
            await AppDataSource.destroy();
        }
    });

    it("should successfully insert and retrieve a Token", async () => {
        const tokenRepo = AppDataSource.getRepository(Token);
        const token = tokenRepo.create({
            address: "0x1234567890123456789012345678901234567890",
            chainId: 8453,
            deployer: "0xdeployer00000000000000000000000000000000",
            deployedAt: new Date(),
            hasUnlimitedMint: false,
            hasBlacklist: false,
            hasTax: true,
            liquidityLocked: true,
            topHolderConcentration: 0.2543,
        });

        const savedToken = await tokenRepo.save(token);
        expect(savedToken.id).toBeDefined();

        const foundToken = await tokenRepo.findOneBy({ id: savedToken.id });
        expect(foundToken).not.toBeNull();
        expect(foundToken?.address).toBe(token.address.toLowerCase() === token.address ? token.address : token.address);
        expect(Number(foundToken?.topHolderConcentration)).toBeCloseTo(0.2543, 4);
    });

    it("should cascadingly delete risk assessment when token is deleted", async () => {
        const tokenRepo = AppDataSource.getRepository(Token);
        const assessmentRepo = AppDataSource.getRepository(RiskAssessment);

        const token = await tokenRepo.save(
            tokenRepo.create({
                address: "0x9876543210987654321098765432109876543210",
                chainId: 8453,
                deployer: "0xdeployer00000000000000000000000000000000",
                deployedAt: new Date(),
            })
        );

        const assessment = await assessmentRepo.save(
            assessmentRepo.create({
                tokenId: token.id,
                probability: 0.85,
                reasoning: "High concentration of supply.",
                confidence: 0.9,
                llmModel: "gpt-4o",
                assessedAt: new Date(),
            })
        );

        expect(assessment.id).toBeDefined();

        // Delete token
        await tokenRepo.delete(token.id);

        const deletedAssessment = await assessmentRepo.findOneBy({ id: assessment.id });
        expect(deletedAssessment).toBeNull();
    });

    it("should successfully manage full prediction pool flow: pools, positions, resolution, attestations", async () => {
        const tokenRepo = AppDataSource.getRepository(Token);
        const assessmentRepo = AppDataSource.getRepository(RiskAssessment);
        const poolRepo = AppDataSource.getRepository(PredictionPool);
        const posRepo = AppDataSource.getRepository(Position);
        const resRepo = AppDataSource.getRepository(ResolutionEvent);
        const attRepo = AppDataSource.getRepository(Attestation);

        const token = await tokenRepo.save(
            tokenRepo.create({
                address: "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd",
                chainId: 8453,
                deployer: "0xdeployer00000000000000000000000000000000",
                deployedAt: new Date(),
            })
        );

        const assessment = await assessmentRepo.save(
            assessmentRepo.create({
                tokenId: token.id,
                probability: 0.1234,
                reasoning: "Safe LP locks.",
                confidence: 0.95,
                llmModel: "gpt-4o-mini",
                assessedAt: new Date(),
            })
        );

        // 1. Create Prediction Pool
        const pool = await poolRepo.save(
            poolRepo.create({
                tokenId: token.id,
                assessmentId: assessment.id,
                contractAddress: "0xpoolcontractaddress0000000000000000000",
                yesPoolAmount: "1000000000000000000", // 1 ETH
                noPoolAmount: "2000000000000000000",  // 2 ETH
                status: "active",
                deadline: new Date(Date.now() + 86400000),
            })
        );
        expect(pool.id).toBeDefined();

        // 2. Buy Position
        const position = await posRepo.save(
            posRepo.create({
                poolId: pool.id,
                userAddress: "0xuser000000000000000000000000000000000001",
                side: "YES",
                amount: "1000000000000000000",
                claimed: false,
            })
        );
        expect(position.id).toBeDefined();

        // Verify unique pool_id + user_address constraint
        await expect(
            posRepo.save(
                posRepo.create({
                    poolId: pool.id,
                    userAddress: "0xuser000000000000000000000000000000000001",
                    side: "NO",
                    amount: "500000000000000000",
                })
            )
        ).rejects.toThrow();

        // 3. Resolve Pool (Resolution Event)
        const resolution = await resRepo.save(
            resRepo.create({
                poolId: pool.id,
                liquidityPulled: false,
                winningSide: "NO",
                txHash: "0xhash0000000000000000000000000000000000000000000000000000000001",
            })
        );
        expect(resolution.id).toBeDefined();

        // 4. Attestation
        const attestation = await attRepo.save(
            attRepo.create({
                poolId: pool.id, // linked to resolution pool_id
                easUid: "0xeasuid000000000000000000000000000000000000000000000000000000001",
                predictedOutcome: true, // we predicted rug
                actualOutcome: false,    // actually safe
            })
        );
        expect(attestation.id).toBeDefined();

        // Check constraint: invalid winning side or status check triggers db error
        await expect(
            poolRepo.save(
                poolRepo.create({
                    tokenId: token.id,
                    assessmentId: assessment.id,
                    contractAddress: "0xpoolcontractaddress0000000000000000002",
                    status: "invalidstatus" as any,
                    deadline: new Date(),
                })
            )
        ).rejects.toThrow();
    });
});
```
- [ ] **Step 3: Run the integration tests**
      Run: `DATABASE_URL=postgresql://dev:dev@localhost:5432/rugradar_dev bun test src/common/database.spec.ts`
      Expected: All test cases pass successfully.
- [ ] **Step 4: Commit**
      Run: `git add src/common/database.spec.ts && git commit -m "test(backend): add database schema and migration integration tests"`
