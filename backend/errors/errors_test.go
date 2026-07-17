package errors

import (
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
)

func TestWriteError(t *testing.T) {
	t.Run("AppError serializes correctly", func(t *testing.T) {
		rec := httptest.NewRecorder()
		appErr := New(http.StatusBadRequest, "Invalid input data", "INVALID_INPUT")
		WriteError(rec, appErr)

		if rec.Code != http.StatusBadRequest {
			t.Errorf("expected status %d, got %d", http.StatusBadRequest, rec.Code)
		}

		var body map[string]interface{}
		if err := json.NewDecoder(rec.Body).Decode(&body); err != nil {
			t.Fatalf("failed to decode response: %v", err)
		}

		if body["status"] != "error" || body["message"] != "Invalid input data" || body["code"] != "INVALID_INPUT" {
			t.Errorf("unexpected body: %v", body)
		}
	})

	t.Run("Normal error in non-prod defaults to message", func(t *testing.T) {
		os.Setenv("ENV", "dev")
		rec := httptest.NewRecorder()
		normalErr := errors.New("db disconnect issue")
		WriteError(rec, normalErr)

		if rec.Code != http.StatusInternalServerError {
			t.Errorf("expected status 500, got %d", rec.Code)
		}

		var body map[string]interface{}
		_ = json.NewDecoder(rec.Body).Decode(&body)

		if body["message"] != "db disconnect issue" {
			t.Errorf("expected message 'db disconnect issue', got '%v'", body["message"])
		}
	})

	t.Run("Normal error in prod sanitizes to Internal Server Error", func(t *testing.T) {
		os.Setenv("ENV", "prod")
		rec := httptest.NewRecorder()
		normalErr := errors.New("secret DB password leaked")
		WriteError(rec, normalErr)

		var body map[string]interface{}
		_ = json.NewDecoder(rec.Body).Decode(&body)

		if body["message"] != "Internal Server Error" {
			t.Errorf("expected sanitized message, got '%v'", body["message"])
		}
	})
}
