package errors

import (
	"encoding/json"
	"errors"
	"net/http"
	"os"
)

type AppError struct {
	StatusCode int    `json:"status_code"`
	Message    string `json:"message"`
	Code       string `json:"code,omitempty"`
}

func (e *AppError) Error() string {
	return e.Message
}

func New(statusCode int, message string, code string) *AppError {
	return &AppError{
		StatusCode: statusCode,
		Message:    message,
		Code:       code,
	}
}

func WriteError(w http.ResponseWriter, err error) {
	w.Header().Set("Content-Type", "application/json")

	var appErr *AppError
	if errors.As(err, &appErr) {
		w.WriteHeader(appErr.StatusCode)
		payload := map[string]interface{}{
			"status":  "error",
			"message": appErr.Message,
		}
		if appErr.Code != "" {
			payload["code"] = appErr.Code
		}
		_ = json.NewEncoder(w).Encode(payload)
		return
	}

	w.WriteHeader(http.StatusInternalServerError)

	message := "Internal Server Error"
	env := os.Getenv("NODE_ENV")
	if env == "" {
		env = os.Getenv("ENV")
	}
	if env != "production" && env != "prod" {
		message = err.Error()
	}

	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":  "error",
		"message": message,
	})
}
