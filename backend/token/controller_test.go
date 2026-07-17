package token

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"guardai-be/config"
	"guardai-be/db"
	"guardai-be/models"
)

func TestTokenController(t *testing.T) {
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

	repo := NewRepository(pool)
	service := NewService(repo, "http://localhost:8545")
	ctrl := NewController(service)

	mux := http.NewServeMux()
	mux.HandleFunc("GET /api/v1/tokens", ctrl.ListTokens)
	mux.HandleFunc("GET /api/v1/tokens/{address}", ctrl.GetTokenByAddress)
	mux.HandleFunc("GET /api/v1/tokens/{address}/assessments", ctrl.GetAssessmentsByAddress)

	_, _ = pool.Exec(ctx, "TRUNCATE tokens CASCADE")

	tokenAddr := "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	tok := &models.Token{
		Address:          tokenAddr,
		ChainID:          8453,
		Deployer:         "0x0000000000000000000000000000000000000000",
		DeployedAt:       time.Now(),
		HasUnlimitedMint: nil,
		HasBlacklist:     nil,
		HasTax:           nil,
		CreatedAt:        time.Now(),
		UpdatedAt:        time.Now(),
	}
	if err := repo.Save(ctx, tok); err != nil {
		t.Fatalf("failed to seed token: %v", err)
	}

	tok, err = repo.FindByAddress(ctx, tokenAddr)
	if err != nil || tok == nil {
		t.Fatalf("failed to retrieve seeded token: %v", err)
	}

	assess := &models.RiskAssessment{
		TokenID:     tok.ID,
		Probability: 0.85,
		Reasoning:   "Testing controller",
		Confidence:  0.9,
		LLMModel:    "test-model",
		AssessedAt:  time.Now(),
		CreatedAt:   time.Now(),
	}
	if err := repo.SaveAssessment(ctx, assess); err != nil {
		t.Fatalf("failed to seed assessment: %v", err)
	}

	t.Run("GET /api/v1/tokens - Happy Path", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/api/v1/tokens?page=1&limit=10", nil)
		rec := httptest.NewRecorder()

		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Errorf("expected status 200, got %d", rec.Code)
		}

		var resp map[string]interface{}
		if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
			t.Fatalf("failed to parse JSON response: %v", err)
		}

		if resp["success"] != true {
			t.Error("expected success to be true")
		}

		data, ok := resp["data"].([]interface{})
		if !ok || len(data) == 0 {
			t.Fatal("expected non-empty data list")
		}
	})

	t.Run("GET /api/v1/tokens - Boundary values", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/api/v1/tokens?page=-1&limit=999", nil)
		rec := httptest.NewRecorder()

		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Errorf("expected status 200, got %d", rec.Code)
		}

		var resp map[string]interface{}
		_ = json.Unmarshal(rec.Body.Bytes(), &resp)
		meta := resp["meta"].(map[string]interface{})
		if meta["limit"].(float64) != 100 {
			t.Errorf("expected limit capped to 100, got %v", meta["limit"])
		}
		if meta["page"].(float64) != 1 {
			t.Errorf("expected page default to 1, got %v", meta["page"])
		}
	})

	t.Run("GET /api/v1/tokens/{address} - Happy Path", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/api/v1/tokens/"+tokenAddr, nil)
		rec := httptest.NewRecorder()

		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Errorf("expected status 200, got %d", rec.Code)
		}

		var resp map[string]interface{}
		if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
			t.Fatalf("failed to parse JSON response: %v", err)
		}

		if resp["success"] != true {
			t.Error("expected success to be true")
		}

		data := resp["data"].(map[string]interface{})
		if data["address"] != tokenAddr {
			t.Errorf("expected address %s, got %v", tokenAddr, data["address"])
		}

		latestAssess := data["latest_assessment"].(map[string]interface{})
		if latestAssess["probability"].(float64) != 0.85 {
			t.Errorf("expected assessment probability 0.85, got %v", latestAssess["probability"])
		}
	})

	t.Run("GET /api/v1/tokens/{address} - Invalid Address Format", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/api/v1/tokens/invalidaddress", nil)
		rec := httptest.NewRecorder()

		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusBadRequest {
			t.Errorf("expected status 400, got %d", rec.Code)
		}

		var resp map[string]interface{}
		_ = json.Unmarshal(rec.Body.Bytes(), &resp)

		if resp["status"] != "error" {
			t.Errorf("expected status to be error, got %v", resp["status"])
		}
		if resp["code"] != "INVALID_ADDRESS" {
			t.Errorf("expected error code INVALID_ADDRESS, got %v", resp["code"])
		}
	})

	t.Run("GET /api/v1/tokens/{address} - Token Not Found", func(t *testing.T) {
		nonExistent := "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
		req := httptest.NewRequest("GET", "/api/v1/tokens/"+nonExistent, nil)
		rec := httptest.NewRecorder()

		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusNotFound {
			t.Errorf("expected status 404, got %d", rec.Code)
		}

		var resp map[string]interface{}
		_ = json.Unmarshal(rec.Body.Bytes(), &resp)

		if resp["status"] != "error" {
			t.Errorf("expected status to be error, got %v", resp["status"])
		}
		if resp["code"] != "TOKEN_NOT_FOUND" {
			t.Errorf("expected error code TOKEN_NOT_FOUND, got %v", resp["code"])
		}
	})

	t.Run("GET /api/v1/tokens/{address}/assessments - Happy Path", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/api/v1/tokens/"+tokenAddr+"/assessments", nil)
		rec := httptest.NewRecorder()

		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusOK {
			t.Errorf("expected status 200, got %d", rec.Code)
		}

		var resp map[string]interface{}
		if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
			t.Fatalf("failed to parse JSON response: %v", err)
		}

		if resp["success"] != true {
			t.Error("expected success to be true")
		}

		data := resp["data"].([]interface{})
		if len(data) != 1 {
			t.Errorf("expected 1 assessment, got %d", len(data))
		}
	})

	t.Run("GET /api/v1/tokens/{address}/assessments - Invalid Address Format", func(t *testing.T) {
		req := httptest.NewRequest("GET", "/api/v1/tokens/invalid/assessments", nil)
		rec := httptest.NewRecorder()

		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusBadRequest {
			t.Errorf("expected status 400, got %d", rec.Code)
		}

		var resp map[string]interface{}
		_ = json.Unmarshal(rec.Body.Bytes(), &resp)

		if resp["status"] != "error" {
			t.Errorf("expected status to be error, got %v", resp["status"])
		}
		if resp["code"] != "INVALID_ADDRESS" {
			t.Errorf("expected error code INVALID_ADDRESS, got %v", resp["code"])
		}
	})

	t.Run("GET /api/v1/tokens/{address}/assessments - Token Not Found", func(t *testing.T) {
		nonExistent := "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
		req := httptest.NewRequest("GET", "/api/v1/tokens/"+nonExistent+"/assessments", nil)
		rec := httptest.NewRecorder()

		mux.ServeHTTP(rec, req)

		if rec.Code != http.StatusNotFound {
			t.Errorf("expected status 404, got %d", rec.Code)
		}

		var resp map[string]interface{}
		_ = json.Unmarshal(rec.Body.Bytes(), &resp)

		if resp["status"] != "error" {
			t.Errorf("expected status to be error, got %v", resp["status"])
		}
		if resp["code"] != "TOKEN_NOT_FOUND" {
			t.Errorf("expected error code TOKEN_NOT_FOUND, got %v", resp["code"])
		}
	})
}
