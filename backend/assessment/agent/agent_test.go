package agent

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestValidateLLMOutput(t *testing.T) {
	t.Run("Valid JSON output", func(t *testing.T) {
		raw := `{"probability": 0.85, "reasoning": "Unlimited mint detected.", "confidence": 0.90, "riskFactors": ["unlimited_mint", "invalid_factor"]}`
		out, err := ValidateLLMOutput(raw)
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if out.Probability != 0.85 {
			t.Errorf("expected probability 0.85, got %f", out.Probability)
		}
		if len(out.RiskFactors) != 1 || out.RiskFactors[0] != "unlimited_mint" {
			t.Errorf("expected risk factors [unlimited_mint], got %v", out.RiskFactors)
		}
	})

	t.Run("Truncates reasoning to word boundary", func(t *testing.T) {
		reasoning := "This is a very long reasoning string that should exceed the 200 characters limit. It will be truncated at a word boundary to prevent cutting off words in the middle of the sentence. Let us check if this works correctly."
		raw := `{"probability": 0.5, "reasoning": "` + reasoning + `", "confidence": 0.8, "riskFactors": []}`
		out, err := ValidateLLMOutput(raw)
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if len(out.Reasoning) > 200 {
			t.Errorf("expected reasoning length <= 200, got %d", len(out.Reasoning))
		}
	})

	t.Run("Out of range validation", func(t *testing.T) {
		raw := `{"probability": 1.5, "reasoning": "Too high.", "confidence": 0.90, "riskFactors": []}`
		_, err := ValidateLLMOutput(raw)
		if err == nil {
			t.Error("expected error for probability out of range")
		}
	})

	t.Run("Malformed JSON", func(t *testing.T) {
		raw := `{"probability": 0.5, "reasoning": "bad json`
		_, err := ValidateLLMOutput(raw)
		if err == nil {
			t.Error("expected error for malformed json")
		}
	})
}

func TestLLMClient_Generate(t *testing.T) {
	t.Run("Success path", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusOK)
			_, _ = w.Write([]byte(`{"choices":[{"message":{"content":"response content"}}]}`))
		}))
		defer server.Close()

		client := NewLLMClient("test-key", "gpt-4o-mini")
		client.CustomURL = server.URL

		resp, err := client.Generate(context.Background(), "sys", "user")
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if resp != "response content" {
			t.Errorf("expected 'response content', got %s", resp)
		}
	})

	t.Run("Immediate API Error (401 Unauthorized)", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusUnauthorized)
			_, _ = w.Write([]byte(`{"error":{"message":"Invalid key"}}`))
		}))
		defer server.Close()

		client := NewLLMClient("test-key", "gpt-4o-mini")
		client.CustomURL = server.URL

		_, err := client.Generate(context.Background(), "sys", "user")
		if err == nil {
			t.Fatal("expected error on 401 response status")
		}
		if !containsString(err.Error(), "401") || !containsString(err.Error(), "Invalid key") {
			t.Errorf("expected detailed 401 error message, got: %v", err)
		}
	})

	t.Run("Retry Exhaustion (500 Error)", func(t *testing.T) {
		calls := 0
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			calls++
			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusInternalServerError)
		}))
		defer server.Close()

		client := NewLLMClient("test-key", "gpt-4o-mini")
		client.CustomURL = server.URL

		_, err := client.Generate(context.Background(), "sys", "user")
		if err == nil {
			t.Fatal("expected error on 500 status code after exhaustion")
		}
		// Expect 3 total attempts (attempt 0, then backoffs: 1s, 2s)
		if calls != 3 {
			t.Errorf("expected 3 server calls, got %d", calls)
		}
	})

	t.Run("Context Timeout check", func(t *testing.T) {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// slow server
			time.Sleep(500 * time.Millisecond)
			w.WriteHeader(http.StatusOK)
		}))
		defer server.Close()

		client := NewLLMClient("test-key", "gpt-4o-mini")
		client.CustomURL = server.URL

		ctx, cancel := context.WithTimeout(context.Background(), 50*time.Millisecond)
		defer cancel()

		_, err := client.Generate(ctx, "sys", "user")
		if err == nil {
			t.Fatal("expected context timeout error")
		}
	})
}

func containsString(s, substr string) bool {
	// simple helper
	lenSub := len(substr)
	if lenSub == 0 {
		return true
	}
	for i := 0; i+lenSub <= len(s); i++ {
		if s[i:i+lenSub] == substr {
			return true
		}
	}
	return false
}
