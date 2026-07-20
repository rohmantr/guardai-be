package agent

import (
	"encoding/json"
	"errors"
	"strings"
)

type LLMOutput struct {
	Probability float64  `json:"probability"`
	Reasoning   string   `json:"reasoning"`
	Confidence  float64  `json:"confidence"`
	RiskFactors []string `json:"riskFactors"`
}

var allowedRiskFactors = map[string]bool{
	"unlimited_mint":            true,
	"blacklist_function":        true,
	"transfer_tax":              true,
	"liquidity_not_locked":      true,
	"liquidity_low":             true,
	"high_holder_concentration": true,
	"deployer_holds_large":      true,
	"honeypot_detected":         true,
	"insufficient_data":         true,
	"no_verified_source":        true,
	"proxy_contract":            true,
	"ownership_renounced":       true,
}

func ValidateLLMOutput(raw string) (*LLMOutput, error) {
	var out LLMOutput
	if err := json.Unmarshal([]byte(raw), &out); err != nil {
		return nil, err
	}

	if out.Probability < 0.0 || out.Probability > 1.0 {
		return nil, errors.New("probability out of range [0,1]")
	}
	if out.Confidence < 0.0 || out.Confidence > 1.0 {
		return nil, errors.New("confidence out of range [0,1]")
	}

	out.Reasoning = strings.TrimSpace(out.Reasoning)
	if len(out.Reasoning) == 0 {
		return nil, errors.New("reasoning cannot be empty")
	}

	if len(out.Reasoning) > 200 {
		out.Reasoning = truncateToWordBoundary(out.Reasoning, 200)
	}

	var filteredFactors []string
	for _, factor := range out.RiskFactors {
		if allowedRiskFactors[factor] {
			filteredFactors = append(filteredFactors, factor)
		}
	}
	out.RiskFactors = filteredFactors

	return &out, nil
}

func truncateToWordBoundary(s string, max int) string {
	if len(s) <= max {
		return s
	}
	sub := s[:max]
	lastSpace := strings.LastIndex(sub, " ")
	if lastSpace > 0 {
		return strings.TrimSpace(sub[:lastSpace])
	}
	return sub
}
