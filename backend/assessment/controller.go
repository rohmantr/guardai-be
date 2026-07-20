package assessment

import (
	"encoding/json"
	"net/http"
	"strings"

	"guardai-be/errors"
	"guardai-be/token"
)

type Controller struct {
	service        *Service
	internalAPIKey string
}

func NewController(service *Service, internalAPIKey string) *Controller {
	return &Controller{
		service:        service,
		internalAPIKey: internalAPIKey,
	}
}

type assessRequest struct {
	TokenAddress string `json:"token_address"`
}

func (c *Controller) TriggerAssessment(w http.ResponseWriter, r *http.Request) {
	// API Key Auth check
	apiKey := r.Header.Get("X-API-Key")
	if c.internalAPIKey != "" && apiKey != c.internalAPIKey {
		errors.WriteError(w, errors.New(http.StatusUnauthorized, "Unauthorized", "RR_AUTH_UNAUTHORIZED"))
		return
	}

	ctx := r.Context()
	var req assessRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		errors.WriteError(w, errors.New(http.StatusBadRequest, "Invalid request body", "INVALID_REQUEST"))
		return
	}

	req.TokenAddress = strings.TrimSpace(req.TokenAddress)
	if !token.IsValidAddress(req.TokenAddress) {
		errors.WriteError(w, errors.New(http.StatusBadRequest, "Invalid ethereum address format", "INVALID_ADDRESS"))
		return
	}

	assessment, fresh, err := c.service.Assess(ctx, req.TokenAddress)
	if err != nil {
		if err.Error() == "token not found" {
			errors.WriteError(w, errors.New(http.StatusNotFound, "Token not found", "TOKEN_NOT_FOUND"))
			return
		}
		errors.WriteError(w, err)
		return
	}

	statusCode := http.StatusOK
	if fresh {
		statusCode = http.StatusCreated
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"data":    assessment,
	})
}

func (c *Controller) GetAssessmentByID(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	id := r.PathValue("id")

	assessment, err := c.service.GetAssessment(ctx, id)
	if err != nil {
		errors.WriteError(w, err)
		return
	}

	if assessment == nil {
		errors.WriteError(w, errors.New(http.StatusNotFound, "Assessment not found", "ASSESSMENT_NOT_FOUND"))
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"data":    assessment,
	})
}
