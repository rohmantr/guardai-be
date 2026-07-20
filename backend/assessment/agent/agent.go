package agent

import (
	"context"

	"guardai-be/models"
)

type RiskAgent struct {
	client *LLMClient
}

func NewRiskAgent(client *LLMClient) *RiskAgent {
	return &RiskAgent{client: client}
}

type AssessmentResult struct {
	Probability float64
	Reasoning   string
	Confidence  float64
	RiskFactors []string
	Source      string
	RawResponse *string
}

const (
	SourceLLM      = "llm"
	SourceFallback = "fallback"
)

func fallbackResult(raw *string) AssessmentResult {
	return AssessmentResult{
		Probability: 0.5,
		Reasoning:   "Assessment failed due to LLM error. Defaulting to neutral risk.",
		Confidence:  0.1,
		RiskFactors: []string{"insufficient_data"},
		Source:      SourceFallback,
		RawResponse: raw,
	}
}

func (a *RiskAgent) Run(ctx context.Context, t *models.Token) AssessmentResult {
	systemPrompt, userPrompt := BuildRiskAnalysisPrompt(t)

	raw, err := a.client.Generate(ctx, systemPrompt, userPrompt)
	if err != nil {
		return fallbackResult(nil)
	}

	validated, err := ValidateLLMOutput(raw)
	if err != nil {
		return fallbackResult(&raw)
	}

	return AssessmentResult{
		Probability: validated.Probability,
		Reasoning:   validated.Reasoning,
		Confidence:  validated.Confidence,
		RiskFactors: validated.RiskFactors,
		Source:      SourceLLM,
		RawResponse: &raw,
	}
}
