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
    expect(foundToken?.address).toBe(token.address);
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
      }),
    );

    const assessment = await assessmentRepo.save(
      assessmentRepo.create({
        tokenId: token.id,
        probability: 0.85,
        reasoning: "High concentration of supply.",
        confidence: 0.9,
        llmModel: "gpt-4o",
        assessedAt: new Date(),
      }),
    );

    expect(assessment.id).toBeDefined();

    // Delete token
    await tokenRepo.delete(token.id);

    const deletedAssessment = await assessmentRepo.findOneBy({
      id: assessment.id,
    });
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
      }),
    );

    const assessment = await assessmentRepo.save(
      assessmentRepo.create({
        tokenId: token.id,
        probability: 0.1234,
        reasoning: "Safe LP locks.",
        confidence: 0.95,
        llmModel: "gpt-4o-mini",
        assessedAt: new Date(),
      }),
    );

    // 1. Create Prediction Pool
    const pool = await poolRepo.save(
      poolRepo.create({
        tokenId: token.id,
        assessmentId: assessment.id,
        contractAddress: "0xpoolcontractaddress0000000000000000000",
        yesPoolAmount: "1000000000000000000", // 1 ETH
        noPoolAmount: "2000000000000000000", // 2 ETH
        status: "active",
        deadline: new Date(Date.now() + 86400000),
      }),
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
      }),
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
        }),
      ),
    ).rejects.toThrow();

    // 3. Resolve Pool (Resolution Event)
    const resolution = await resRepo.save(
      resRepo.create({
        poolId: pool.id,
        liquidityPulled: false,
        winningSide: "NO",
        txHash:
          "0xhash0000000000000000000000000000000000000000000000000000000001",
      }),
    );
    expect(resolution.id).toBeDefined();

    // 4. Attestation
    const attestation = await attRepo.save(
      attRepo.create({
        poolId: pool.id, // linked to resolution pool_id
        easUid:
          "0xeasuid000000000000000000000000000000000000000000000000000000001",
        predictedOutcome: true, // we predicted rug
        actualOutcome: false, // actually safe
      }),
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
        }),
      ),
    ).rejects.toThrow();
  });
});
