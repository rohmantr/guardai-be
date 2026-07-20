package assessment

import (
	"context"

	"guardai-be/models"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Repository struct {
	pool *pgxpool.Pool
}

func NewRepository(pool *pgxpool.Pool) *Repository {
	return &Repository{pool: pool}
}

func (r *Repository) Save(ctx context.Context, a *models.RiskAssessment) error {
	var err error
	if a.ID == "" {
		err = r.pool.QueryRow(ctx, `
			INSERT INTO risk_assessments (token_id, probability, reasoning, confidence, llm_model, source, raw_response, assessed_at, created_at)
			VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
			RETURNING id
		`, a.TokenID, a.Probability, a.Reasoning, a.Confidence, a.LLMModel, a.Source, a.RawResponse, a.AssessedAt, a.CreatedAt).Scan(&a.ID)
	} else {
		_, err = r.pool.Exec(ctx, `
			INSERT INTO risk_assessments (id, token_id, probability, reasoning, confidence, llm_model, source, raw_response, assessed_at, created_at)
			VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
			ON CONFLICT (id) DO UPDATE SET
				probability = EXCLUDED.probability,
				reasoning = EXCLUDED.reasoning,
				confidence = EXCLUDED.confidence,
				llm_model = EXCLUDED.llm_model,
				source = EXCLUDED.source,
				raw_response = EXCLUDED.raw_response,
				assessed_at = EXCLUDED.assessed_at
		`, a.ID, a.TokenID, a.Probability, a.Reasoning, a.Confidence, a.LLMModel, a.Source, a.RawResponse, a.AssessedAt, a.CreatedAt)
	}
	return err
}

func (r *Repository) FindByID(ctx context.Context, id string) (*models.RiskAssessment, error) {
	row := r.pool.QueryRow(ctx, `
		SELECT id, token_id, probability, reasoning, confidence, llm_model, source, raw_response, assessed_at, created_at
		FROM risk_assessments
		WHERE id = $1
	`, id)
	var a models.RiskAssessment
	err := row.Scan(
		&a.ID, &a.TokenID, &a.Probability, &a.Reasoning, &a.Confidence, &a.LLMModel, &a.Source, &a.RawResponse, &a.AssessedAt, &a.CreatedAt,
	)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}
	return &a, nil
}

func (r *Repository) FindLatestByTokenID(ctx context.Context, tokenID string) (*models.RiskAssessment, error) {
	row := r.pool.QueryRow(ctx, `
		SELECT id, token_id, probability, reasoning, confidence, llm_model, source, raw_response, assessed_at, created_at
		FROM risk_assessments
		WHERE token_id = $1
		ORDER BY assessed_at DESC
		LIMIT 1
	`, tokenID)
	var a models.RiskAssessment
	err := row.Scan(
		&a.ID, &a.TokenID, &a.Probability, &a.Reasoning, &a.Confidence, &a.LLMModel, &a.Source, &a.RawResponse, &a.AssessedAt, &a.CreatedAt,
	)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}
	return &a, nil
}
