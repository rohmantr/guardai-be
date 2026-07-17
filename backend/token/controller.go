package token

import (
	"encoding/json"
	"net/http"
	"regexp"
	"strconv"

	"guardai-be/errors"
)

var addressRegex = regexp.MustCompile(`^0x[0-9a-fA-F]{40}$`)

func IsValidAddress(address string) bool {
	return addressRegex.MatchString(address)
}

type Controller struct {
	service *Service
}

func NewController(service *Service) *Controller {
	return &Controller{service: service}
}

func (c *Controller) ListTokens(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	q := r.URL.Query()
	pageStr := q.Get("page")
	limitStr := q.Get("limit")
	search := q.Get("search")

	page := 1
	if pageStr != "" {
		if p, err := strconv.Atoi(pageStr); err == nil && p > 0 {
			page = p
		}
	}

	limit := 20
	if limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil && l > 0 {
			limit = l
		}
	}

	tokens, total, err := c.service.ListTokens(ctx, page, limit, search)
	if err != nil {
		errors.WriteError(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"data":    tokens,
		"meta": map[string]interface{}{
			"page":  page,
			"limit": limit,
			"total": total,
		},
	})
}

func (c *Controller) GetTokenByAddress(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	address := r.PathValue("address")

	if !IsValidAddress(address) {
		errors.WriteError(w, errors.New(http.StatusBadRequest, "Invalid ethereum address format", "INVALID_ADDRESS"))
		return
	}

	token, assessment, err := c.service.GetTokenWithLatestAssessment(ctx, address)
	if err != nil {
		errors.WriteError(w, err)
		return
	}

	if token == nil {
		errors.WriteError(w, errors.New(http.StatusNotFound, "Token not found", "TOKEN_NOT_FOUND"))
		return
	}

	data := map[string]interface{}{
		"id":                       token.ID,
		"address":                  token.Address,
		"chain_id":                 token.ChainID,
		"deployer":                 token.Deployer,
		"deployed_at":              token.DeployedAt,
		"has_unlimited_mint":       token.HasUnlimitedMint,
		"has_blacklist":            token.HasBlacklist,
		"has_tax":                  token.HasTax,
		"liquidity_locked":         token.LiquidityLocked,
		"top_holder_concentration": token.TopHolderConcentration,
		"created_at":               token.CreatedAt,
		"updated_at":               token.UpdatedAt,
		"latest_assessment":        assessment,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"data":    data,
	})
}

func (c *Controller) GetAssessmentsByAddress(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	address := r.PathValue("address")

	if !IsValidAddress(address) {
		errors.WriteError(w, errors.New(http.StatusBadRequest, "Invalid ethereum address format", "INVALID_ADDRESS"))
		return
	}

	token, err := c.service.GetToken(ctx, address)
	if err != nil {
		errors.WriteError(w, err)
		return
	}
	if token == nil {
		errors.WriteError(w, errors.New(http.StatusNotFound, "Token not found", "TOKEN_NOT_FOUND"))
		return
	}

	assessments, err := c.service.GetAssessments(ctx, address)
	if err != nil {
		errors.WriteError(w, err)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"data":    assessments,
	})
}
