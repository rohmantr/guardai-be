package token

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"guardai-be/config"
	"guardai-be/db"
	"guardai-be/models"
)

func TestTokenService(t *testing.T) {
	cfg := config.LoadConfig()
	ctx := context.Background()

	pool, err := db.Connect(cfg.DatabaseURL)
	if err != nil {
		t.Fatalf("failed to connect to database: %v", err)
	}
	defer pool.Close()

	if err := db.RunMigrations(ctx, pool); err != nil {
		t.Fatalf("failed to run migrations: %v", err)
	}

	_, _ = pool.Exec(ctx, "TRUNCATE tokens CASCADE")

	repo := NewRepository(pool)

	// Spin up mock RPC Server
	var mockBytecode string
	mockServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var reqBody map[string]interface{}
		_ = json.NewDecoder(r.Body).Decode(&reqBody)

		method := reqBody["method"].(string)
		w.Header().Set("Content-Type", "application/json")

		if method == "eth_getCode" {
			resp := map[string]interface{}{
				"jsonrpc": "2.0",
				"id":      1,
				"result":  mockBytecode,
			}
			_ = json.NewEncoder(w).Encode(resp)
		} else if method == "eth_getBlockByNumber" {
			resp := map[string]interface{}{
				"jsonrpc": "2.0",
				"id":      1,
				"result": map[string]interface{}{
					"transactions": []map[string]interface{}{
						{
							"hash": "0x1111111111111111111111111111111111111111111111111111111111111111",
							"to":   nil,
							"from": "0x2222222222222222222222222222222222222222",
						},
					},
				},
			}
			_ = json.NewEncoder(w).Encode(resp)
		}
	}))
	defer mockServer.Close()

	service := NewService(repo, mockServer.URL)

	t.Run("IsValidAddress validation", func(t *testing.T) {
		if !IsValidAddress("0x1234567890123456789012345678901234567890") {
			t.Error("expected valid address to pass")
		}
		if IsValidAddress("invalid") {
			t.Error("expected invalid address to fail")
		}
	})

	t.Run("ReadContractData - detects risk selectors", func(t *testing.T) {
		// Mock bytecode containing mint selector (40c10f19) and blacklist selector (f9f92be4)
		mockBytecode = "0x608060405234801561001057600080fd5b506004361061002b5760003560e01c806340c10f1914610030578063f9f92be41461004a57"

		data, err := service.ReadContractData(ctx, "0x1234567890123456789012345678901234567890")
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if !data.HasUnlimitedMint {
			t.Error("expected unlimited mint to be detected")
		}
		if !data.HasBlacklist {
			t.Error("expected blacklist to be detected")
		}
	})

	t.Run("DetectNewTokens", func(t *testing.T) {
		// Mock empty bytecode for new deployments
		mockBytecode = "0x00"

		tokens, err := service.DetectNewTokens(ctx)
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		if len(tokens) == 0 {
			t.Fatal("expected at least one token to be detected")
		}

		firstToken := tokens[0]
		if firstToken.Address == "" {
			t.Error("expected address to be set")
		}

		// Verify saved in DB
		saved, err := repo.FindByAddress(ctx, firstToken.Address)
		if err != nil {
			t.Fatalf("failed to find token: %v", err)
		}
		if saved == nil {
			t.Fatal("expected token to be saved in DB")
		}
	})

	t.Run("ListTokens pagination and search", func(t *testing.T) {
		_, _ = pool.Exec(ctx, "TRUNCATE tokens CASCADE")

		// Insert test tokens
		for i := 0; i < 5; i++ {
			addr := fmt.Sprintf("0x%040d", i)
			hasTax := i%2 == 0
			tok := &models.Token{
				Address:    addr,
				ChainID:    8453,
				Deployer:   "0xdeployer",
				DeployedAt: time.Now(),
				HasTax:     &hasTax,
				CreatedAt:  time.Now(),
				UpdatedAt:  time.Now(),
			}
			err := repo.Save(ctx, tok)
			if err != nil {
				t.Fatalf("failed to save: %v", err)
			}
		}

		tokens, total, err := service.ListTokens(ctx, 1, 2, "")
		if err != nil {
			t.Fatalf("failed to list: %v", err)
		}

		if len(tokens) != 2 {
			t.Errorf("expected 2 tokens, got %d", len(tokens))
		}
		if total != 5 {
			t.Errorf("expected total 5, got %d", total)
		}

		// Test search
		tokens, total, err = service.ListTokens(ctx, 1, 2, "0003")
		if err != nil {
			t.Fatalf("failed to list: %v", err)
		}
		if total != 1 {
			t.Errorf("expected search total 1, got %d", total)
		}
	})

	t.Run("GetTokenWithLatestAssessment", func(t *testing.T) {
		_, _ = pool.Exec(ctx, "TRUNCATE tokens CASCADE")

		addr := "0x5555555555555555555555555555555555555555"
		tok := &models.Token{
			Address:    addr,
			ChainID:    8453,
			Deployer:   "0xdeployer",
			DeployedAt: time.Now(),
			CreatedAt:  time.Now(),
			UpdatedAt:  time.Now(),
		}
		_ = repo.Save(ctx, tok)

		// Get token after save (which sets the uuid ID)
		savedTok, err := repo.FindByAddress(ctx, addr)
		if err != nil || savedTok == nil {
			t.Fatalf("failed to get saved token: %v", err)
		}

		assess := &models.RiskAssessment{
			TokenID:     savedTok.ID,
			Probability: 0.95,
			Reasoning:   "Simulated risk assessment",
			Confidence:  0.8,
			LLMModel:    "gpt-4o-mini",
			AssessedAt:  time.Now(),
			CreatedAt:   time.Now(),
		}
		err = repo.SaveAssessment(ctx, assess)
		if err != nil {
			t.Fatalf("failed to save assessment: %v", err)
		}

		tokRes, assessRes, err := service.GetTokenWithLatestAssessment(ctx, addr)
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if tokRes == nil {
			t.Fatal("expected token")
		}
		if assessRes == nil {
			t.Fatal("expected assessment")
		}
		if assessRes.Probability != 0.95 {
			t.Errorf("expected probability 0.95, got %f", assessRes.Probability)
		}
	})
}
