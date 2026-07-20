package assessment

import (
	"context"
	"errors"
	"time"

	"guardai-be/assessment/agent"
	"guardai-be/models"
	"guardai-be/token"
)

type Service struct {
	repo      *Repository
	tokenRepo *token.Repository
	agent     *agent.RiskAgent
	llmModel  string
}

func NewService(repo *Repository, tokenRepo *token.Repository, agent *agent.RiskAgent, llmModel string) *Service {
	return &Service{
		repo:      repo,
		tokenRepo: tokenRepo,
		agent:     agent,
		llmModel:  llmModel,
	}
}

func (s *Service) GetAssessment(ctx context.Context, id string) (*models.RiskAssessment, error) {
	return s.repo.FindByID(ctx, id)
}

func (s *Service) Assess(ctx context.Context, tokenAddress string) (*models.RiskAssessment, bool, error) {
	t, err := s.tokenRepo.FindByAddress(ctx, tokenAddress)
	if err != nil {
		return nil, false, err
	}
	if t == nil {
		return nil, false, errors.New("token not found")
	}

	// Dedup Window check
	latest, err := s.repo.FindLatestByTokenID(ctx, t.ID)
	if err == nil && latest != nil && latest.Source == "llm" {
		if time.Since(latest.AssessedAt) < 10*time.Minute {
			return latest, false, nil
		}
	}

	// Run agent pipeline
	res := s.agent.Run(ctx, t)

	assess := &models.RiskAssessment{
		TokenID:     t.ID,
		Probability: res.Probability,
		Reasoning:   res.Reasoning,
		Confidence:  res.Confidence,
		LLMModel:    s.llmModel,
		Source:      res.Source,
		RawResponse: res.RawResponse,
		AssessedAt:  time.Now(),
		CreatedAt:   time.Now(),
	}

	if err := s.repo.Save(ctx, assess); err != nil {
		return nil, false, err
	}

	return assess, true, nil
}
