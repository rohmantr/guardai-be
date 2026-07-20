package assessment

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"guardai-be/assessment/agent"
	"guardai-be/config"
	"guardai-be/db"
	"guardai-be/models"
	"guardai-be/token"
)

func TestAssessmentFlow(t *testing.T) {
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

	tokenRepo := token.NewRepository(pool)
	assessRepo := NewRepository(pool)

	_, _ = pool.Exec(ctx, "TRUNCATE tokens CASCADE")
	_, _ = pool.Exec(ctx, "TRUNCATE risk_assessments CASCADE")

	// Seed Token
	tokenAddr := "0x1234567890123456789012345678901234567890"
	tok := &models.Token{
		Address:    tokenAddr,
		ChainID:    8453,
		Deployer:   "0xdeployer",
		DeployedAt: time.Now(),
		CreatedAt:  time.Now(),
		UpdatedAt:  time.Now(),
	}
	if err := tokenRepo.Save(ctx, tok); err != nil {
		t.Fatalf("failed to save token: %v", err)
	}

	savedTok, _ := tokenRepo.FindByAddress(ctx, tokenAddr)

	// Mock LLM server
	var llmResponse string
	var llmStatus int = http.StatusOK
	llmServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(llmStatus)
		if llmStatus == http.StatusOK {
			_, _ = w.Write([]byte(llmResponse))
		} else {
			_, _ = w.Write([]byte(`{"error":{"message":"API error"}}`))
		}
	}))
	defer llmServer.Close()

	llmClient := agent.NewLLMClient("test-key", "gpt-4o-mini")
	llmClient.CustomURL = llmServer.URL

	riskAgent := agent.NewRiskAgent(llmClient)
	service := NewService(assessRepo, tokenRepo, riskAgent, "gpt-4o-mini")
	ctrl := NewController(service, "admin-key")

	mux := http.NewServeMux()
	mux.HandleFunc("POST /api/v1/assessments", ctrl.TriggerAssessment)
	mux.HandleFunc("GET /api/v1/assessments/{id}", ctrl.GetAssessmentByID)

	t.Run("POST /api/v1/assessments - Unauthorized", func(t *testing.T) {
		req := httptest.NewRequest("POST", "/api/v1/assessments", strings.NewReader(`{}`))
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		if rec.Code != http.StatusUnauthorized {
			t.Errorf("expected 401, got %d", rec.Code)
		}
	})

	t.Run("POST /api/v1/assessments - Success fresh", func(t *testing.T) {
		// Mock success response
		llmResponse = `{"choices":[{"message":{"content":"{\"probability\": 0.85, \"reasoning\": \"Highly suspicious.\", \"confidence\": 0.90, \"riskFactors\": [\"unlimited_mint\"]}"}}]}
`
		llmStatus = http.StatusOK

		reqBody := `{"token_address": "` + tokenAddr + `"}`
		req := httptest.NewRequest("POST", "/api/v1/assessments", bytes.NewBufferString(reqBody))
		req.Header.Set("X-API-Key", "admin-key")
		rec := httptest.NewRecorder()

		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusCreated {
			t.Fatalf("expected 201, got %d. body: %s", rec.Code, rec.Body.String())
		}

		var resp map[string]interface{}
		_ = json.Unmarshal(rec.Body.Bytes(), &resp)
		data := resp["data"].(map[string]interface{})
		if data["probability"].(float64) != 0.85 {
			t.Errorf("expected probability 0.85, got %v", data["probability"])
		}
		if data["source"].(string) != "llm" {
			t.Errorf("expected source llm, got %s", data["source"])
		}
	})

	t.Run("POST /api/v1/assessments - Success Cached / Dedup", func(t *testing.T) {
		reqBody := `{"token_address": "` + tokenAddr + `"}`
		req := httptest.NewRequest("POST", "/api/v1/assessments", bytes.NewBufferString(reqBody))
		req.Header.Set("X-API-Key", "admin-key")
		rec := httptest.NewRecorder()

		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200 (cached), got %d. body: %s", rec.Code, rec.Body.String())
		}
	})

	t.Run("POST /api/v1/assessments - Fallback triggers when LLM fails", func(t *testing.T) {
		// Seed another token
		addr2 := "0x2222222222222222222222222222222222222222"
		tok2 := &models.Token{
			Address:    addr2,
			ChainID:    8453,
			Deployer:   "0xdeployer",
			DeployedAt: time.Now(),
			CreatedAt:  time.Now(),
			UpdatedAt:  time.Now(),
		}
		_ = tokenRepo.Save(ctx, tok2)

		// Setup LLM failure
		llmStatus = http.StatusInternalServerError

		reqBody := `{"token_address": "` + addr2 + `"}`
		req := httptest.NewRequest("POST", "/api/v1/assessments", bytes.NewBufferString(reqBody))
		req.Header.Set("X-API-Key", "admin-key")
		rec := httptest.NewRecorder()

		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusCreated {
			t.Fatalf("expected 201, got %d", rec.Code)
		}

		var resp map[string]interface{}
		_ = json.Unmarshal(rec.Body.Bytes(), &resp)
		data := resp["data"].(map[string]interface{})
		if data["probability"].(float64) != 0.5 {
			t.Errorf("expected fallback probability 0.5, got %v", data["probability"])
		}
		if data["source"].(string) != "fallback" {
			t.Errorf("expected source fallback, got %s", data["source"])
		}
		if data["raw_response"] != nil {
			t.Errorf("expected nil raw_response on fallback, got %v", data["raw_response"])
		}
	})

	t.Run("GET /api/v1/assessments/{id} - Success & NotFound", func(t *testing.T) {
		// Test NotFound
		req := httptest.NewRequest("GET", "/api/v1/assessments/00000000-0000-0000-0000-000000000000", nil)
		rec := httptest.NewRecorder()
		mux.ServeHTTP(rec, req)
		if rec.Code != http.StatusNotFound {
			t.Errorf("expected 404, got %d", rec.Code)
		}

		// Test Success using ID from first test token
		latest, err := assessRepo.FindLatestByTokenID(ctx, savedTok.ID)
		if err != nil || latest == nil {
			t.Fatalf("failed to query saved assessment: %v", err)
		}

		req = httptest.NewRequest("GET", "/api/v1/assessments/"+latest.ID, nil)
		rec = httptest.NewRecorder()
		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Fatalf("expected 200, got %d", rec.Code)
		}
		var resp map[string]interface{}
		_ = json.Unmarshal(rec.Body.Bytes(), &resp)
		data := resp["data"].(map[string]interface{})
		if data["id"].(string) != latest.ID {
			t.Errorf("expected assessment ID %s, got %s", latest.ID, data["id"])
		}
	})
}
