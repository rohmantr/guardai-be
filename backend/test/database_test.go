package test

import (
	"context"
	"testing"
	"time"

	"guardai-be/config"
	"guardai-be/db"
)

func TestDatabaseIntegration(t *testing.T) {
	cfg := config.LoadConfig()
	ctx := context.Background()

	pool, err := db.Connect(cfg.DatabaseURL)
	if err != nil {
		t.Fatalf("failed to connect to database: %v", err)
	}
	defer pool.Close()

	// Run migrations
	if err := db.RunMigrations(ctx, pool); err != nil {
		t.Fatalf("failed to run migrations: %v", err)
	}

	// Clean up tables
	_, err = pool.Exec(ctx, "TRUNCATE tokens CASCADE")
	if err != nil {
		t.Fatalf("failed to truncate tables: %v", err)
	}

	// 1. Test Token Insertion & Retrieval
	t.Run("Insert and retrieve Token", func(t *testing.T) {
		tokenAddress := "0x1234567890123456789012345678901234567890"
		deployer := "0xdeployer00000000000000000000000000000000"
		deployedAt := time.Now().Truncate(time.Microsecond)
		chainId := 8453
		hasTax := true

		var tokenId string
		err := pool.QueryRow(ctx, `
			INSERT INTO tokens (address, chain_id, deployer, deployed_at, has_tax)
			VALUES ($1, $2, $3, $4, $5)
			RETURNING id
		`, tokenAddress, chainId, deployer, deployedAt, hasTax).Scan(&tokenId)

		if err != nil {
			t.Fatalf("failed to insert token: %v", err)
		}

		if tokenId == "" {
			t.Fatal("expected non-empty tokenId")
		}

		// Retrieve and assert
		var retrievedAddress string
		var retrievedChainId int
		var retrievedHasTax *bool

		err = pool.QueryRow(ctx, `
			SELECT address, chain_id, has_tax
			FROM tokens
			WHERE id = $1
		`, tokenId).Scan(&retrievedAddress, &retrievedChainId, &retrievedHasTax)

		if err != nil {
			t.Fatalf("failed to retrieve token: %v", err)
		}

		if retrievedAddress != tokenAddress {
			t.Errorf("expected address %s, got %s", tokenAddress, retrievedAddress)
		}
		if retrievedChainId != chainId {
			t.Errorf("expected chainId %d, got %d", chainId, retrievedChainId)
		}
		if retrievedHasTax == nil || *retrievedHasTax != hasTax {
			t.Errorf("expected hasTax %v, got %v", hasTax, retrievedHasTax)
		}
	})

	// 2. Test Cascading Delete on Token
	t.Run("Cascading delete on risk assessment", func(t *testing.T) {
		tokenAddress := "0x9876543210987654321098765432109876543210"
		deployer := "0xdeployer00000000000000000000000000000000"
		deployedAt := time.Now().Truncate(time.Microsecond)

		var tokenId string
		err := pool.QueryRow(ctx, `
			INSERT INTO tokens (address, chain_id, deployer, deployed_at)
			VALUES ($1, $2, $3, $4)
			RETURNING id
		`, tokenAddress, 8453, deployer, deployedAt).Scan(&tokenId)
		if err != nil {
			t.Fatalf("failed to insert token: %v", err)
		}

		var assessmentId string
		probability := 0.85
		reasoning := "High concentration of supply."
		confidence := 0.9
		llmModel := "gpt-4o"
		assessedAt := time.Now().Truncate(time.Microsecond)

		err = pool.QueryRow(ctx, `
			INSERT INTO risk_assessments (token_id, probability, reasoning, confidence, llm_model, assessed_at)
			VALUES ($1, $2, $3, $4, $5, $6)
			RETURNING id
		`, tokenId, probability, reasoning, confidence, llmModel, assessedAt).Scan(&assessmentId)
		if err != nil {
			t.Fatalf("failed to insert risk assessment: %v", err)
		}

		// Delete Token
		_, err = pool.Exec(ctx, "DELETE FROM tokens WHERE id = $1", tokenId)
		if err != nil {
			t.Fatalf("failed to delete token: %v", err)
		}

		// Verify assessment is deleted
		var count int
		err = pool.QueryRow(ctx, "SELECT count(*) FROM risk_assessments WHERE id = $1", assessmentId).Scan(&count)
		if err != nil {
			t.Fatalf("failed to query risk assessments: %v", err)
		}
		if count != 0 {
			t.Errorf("expected risk assessment to be cascadingly deleted, but it still exists")
		}
	})

	// 3. Test Full Flow (Pool, Position, Resolution, Attestation)
	t.Run("Full prediction pool flow", func(t *testing.T) {
		tokenAddress := "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd"
		deployer := "0xdeployer00000000000000000000000000000000"
		deployedAt := time.Now().Truncate(time.Microsecond)

		var tokenId string
		err := pool.QueryRow(ctx, `
			INSERT INTO tokens (address, chain_id, deployer, deployed_at)
			VALUES ($1, $2, $3, $4)
			RETURNING id
		`, tokenAddress, 8453, deployer, deployedAt).Scan(&tokenId)
		if err != nil {
			t.Fatalf("failed to insert token: %v", err)
		}

		var assessmentId string
		err = pool.QueryRow(ctx, `
			INSERT INTO risk_assessments (token_id, probability, reasoning, confidence, llm_model, assessed_at)
			VALUES ($1, $2, $3, $4, $5, $6)
			RETURNING id
		`, tokenId, 0.12, "Safe locking.", 0.95, "gpt-4o-mini", time.Now().Truncate(time.Microsecond)).Scan(&assessmentId)
		if err != nil {
			t.Fatalf("failed to insert risk assessment: %v", err)
		}

		// Insert pool
		contractAddress := "0xpool000000000000000000000000000000000000"
		deadline := time.Now().Add(24 * time.Hour).Truncate(time.Microsecond)
		var poolId string
		err = pool.QueryRow(ctx, `
			INSERT INTO prediction_pools (token_id, assessment_id, contract_address, deadline)
			VALUES ($1, $2, $3, $4)
			RETURNING id
		`, tokenId, assessmentId, contractAddress, deadline).Scan(&poolId)
		if err != nil {
			t.Fatalf("failed to insert pool: %v", err)
		}

		// Insert Position
		userAddress := "0xuser000000000000000000000000000000000000"
		amountStr := "1000000000000000000000000000000000" // BigInt numeric
		var positionId string
		err = pool.QueryRow(ctx, `
			INSERT INTO positions (pool_id, user_address, side, amount)
			VALUES ($1, $2, $3, $4)
			RETURNING id
		`, poolId, userAddress, "YES", amountStr).Scan(&positionId)
		if err != nil {
			t.Fatalf("failed to insert position: %v", err)
		}

		// Assert position amount
		var retrievedAmount string
		err = pool.QueryRow(ctx, "SELECT amount FROM positions WHERE id = $1", positionId).Scan(&retrievedAmount)
		if err != nil {
			t.Fatalf("failed to retrieve position amount: %v", err)
		}
		if retrievedAmount != amountStr {
			t.Errorf("expected position amount %s, got %s", amountStr, retrievedAmount)
		}

		// Insert Resolution Event
		txHash := "0xtxhash000000000000000000000000000000000000000000000000000000"
		var resolutionId string
		err = pool.QueryRow(ctx, `
			INSERT INTO resolution_events (pool_id, liquidity_pulled, winning_side, tx_hash)
			VALUES ($1, $2, $3, $4)
			RETURNING id
		`, poolId, true, "YES", txHash).Scan(&resolutionId)
		if err != nil {
			t.Fatalf("failed to insert resolution event: %v", err)
		}

		// Insert Attestation
		easUid := "0xeasuid00000000000000000000000000000000000000000000000000000"
		var attestationId string
		err = pool.QueryRow(ctx, `
			INSERT INTO attestations (pool_id, eas_uid, predicted_outcome, actual_outcome)
			VALUES ($1, $2, $3, $4)
			RETURNING id
		`, poolId, easUid, true, true).Scan(&attestationId)
		if err != nil {
			t.Fatalf("failed to insert attestation: %v", err)
		}

		// Check count
		var attestationCount int
		err = pool.QueryRow(ctx, "SELECT count(*) FROM attestations WHERE id = $1", attestationId).Scan(&attestationCount)
		if err != nil {
			t.Fatalf("failed to query attestation count: %v", err)
		}
		if attestationCount != 1 {
			t.Errorf("expected 1 attestation, got %d", attestationCount)
		}
	})
}
