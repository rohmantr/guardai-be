package token

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

func (r *Repository) FindByAddress(ctx context.Context, address string) (*models.Token, error) {
	row := r.pool.QueryRow(ctx, `
		SELECT id, address, chain_id, deployer, deployed_at, has_unlimited_mint, has_blacklist, has_tax, liquidity_locked, top_holder_concentration, created_at, updated_at
		FROM tokens
		WHERE LOWER(address) = LOWER($1)
	`, address)
	var t models.Token
	err := row.Scan(
		&t.ID, &t.Address, &t.ChainID, &t.Deployer, &t.DeployedAt,
		&t.HasUnlimitedMint, &t.HasBlacklist, &t.HasTax, &t.LiquidityLocked,
		&t.TopHolderConcentration, &t.CreatedAt, &t.UpdatedAt,
	)
	if err != nil {
		if err == pgx.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}
	return &t, nil
}

func (r *Repository) Save(ctx context.Context, t *models.Token) error {
	var err error
	if t.ID == "" {
		err = r.pool.QueryRow(ctx, `
			INSERT INTO tokens (address, chain_id, deployer, deployed_at, has_unlimited_mint, has_blacklist, has_tax, liquidity_locked, top_holder_concentration, created_at, updated_at)
			VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
			ON CONFLICT (address) DO UPDATE SET
				chain_id = EXCLUDED.chain_id,
				deployer = EXCLUDED.deployer,
				deployed_at = EXCLUDED.deployed_at,
				has_unlimited_mint = EXCLUDED.has_unlimited_mint,
				has_blacklist = EXCLUDED.has_blacklist,
				has_tax = EXCLUDED.has_tax,
				liquidity_locked = EXCLUDED.liquidity_locked,
				top_holder_concentration = EXCLUDED.top_holder_concentration,
				updated_at = EXCLUDED.updated_at
			RETURNING id
		`, t.Address, t.ChainID, t.Deployer, t.DeployedAt,
			t.HasUnlimitedMint, t.HasBlacklist, t.HasTax, t.LiquidityLocked,
			t.TopHolderConcentration, t.CreatedAt, t.UpdatedAt).Scan(&t.ID)
	} else {
		_, err = r.pool.Exec(ctx, `
			INSERT INTO tokens (id, address, chain_id, deployer, deployed_at, has_unlimited_mint, has_blacklist, has_tax, liquidity_locked, top_holder_concentration, created_at, updated_at)
			VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
			ON CONFLICT (address) DO UPDATE SET
				chain_id = EXCLUDED.chain_id,
				deployer = EXCLUDED.deployer,
				deployed_at = EXCLUDED.deployed_at,
				has_unlimited_mint = EXCLUDED.has_unlimited_mint,
				has_blacklist = EXCLUDED.has_blacklist,
				has_tax = EXCLUDED.has_tax,
				liquidity_locked = EXCLUDED.liquidity_locked,
				top_holder_concentration = EXCLUDED.top_holder_concentration,
				updated_at = EXCLUDED.updated_at
		`, t.ID, t.Address, t.ChainID, t.Deployer, t.DeployedAt,
			t.HasUnlimitedMint, t.HasBlacklist, t.HasTax, t.LiquidityLocked,
			t.TopHolderConcentration, t.CreatedAt, t.UpdatedAt)
	}
	return err
}

func (r *Repository) SaveAssessment(ctx context.Context, a *models.RiskAssessment) error {
	var err error
	if a.ID == "" {
		err = r.pool.QueryRow(ctx, `
			INSERT INTO risk_assessments (token_id, probability, reasoning, confidence, llm_model, assessed_at, created_at)
			VALUES ($1, $2, $3, $4, $5, $6, $7)
			RETURNING id
		`, a.TokenID, a.Probability, a.Reasoning, a.Confidence, a.LLMModel, a.AssessedAt, a.CreatedAt).Scan(&a.ID)
	} else {
		_, err = r.pool.Exec(ctx, `
			INSERT INTO risk_assessments (id, token_id, probability, reasoning, confidence, llm_model, assessed_at, created_at)
			VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
			ON CONFLICT (id) DO UPDATE SET
				probability = EXCLUDED.probability,
				reasoning = EXCLUDED.reasoning,
				confidence = EXCLUDED.confidence,
				llm_model = EXCLUDED.llm_model,
				assessed_at = EXCLUDED.assessed_at
		`, a.ID, a.TokenID, a.Probability, a.Reasoning, a.Confidence, a.LLMModel, a.AssessedAt, a.CreatedAt)
	}
	return err
}

func (r *Repository) FindTokenWithLatestAssessment(ctx context.Context, address string) (*models.Token, *models.RiskAssessment, error) {
	t, err := r.FindByAddress(ctx, address)
	if err != nil {
		return nil, nil, err
	}
	if t == nil {
		return nil, nil, nil
	}

	row := r.pool.QueryRow(ctx, `
		SELECT id, token_id, probability, reasoning, confidence, llm_model, assessed_at, created_at
		FROM risk_assessments
		WHERE token_id = $1
		ORDER BY assessed_at DESC
		LIMIT 1
	`, t.ID)
	var a models.RiskAssessment
	err = row.Scan(
		&a.ID, &a.TokenID, &a.Probability, &a.Reasoning, &a.Confidence, &a.LLMModel, &a.AssessedAt, &a.CreatedAt,
	)
	if err != nil {
		if err == pgx.ErrNoRows {
			return t, nil, nil
		}
		return nil, nil, err
	}
	return t, &a, nil
}

func (r *Repository) FindAssessmentsByAddress(ctx context.Context, address string) ([]*models.RiskAssessment, error) {
	t, err := r.FindByAddress(ctx, address)
	if err != nil {
		return nil, err
	}
	if t == nil {
		return nil, nil
	}

	rows, err := r.pool.Query(ctx, `
		SELECT id, token_id, probability, reasoning, confidence, llm_model, assessed_at, created_at
		FROM risk_assessments
		WHERE token_id = $1
		ORDER BY assessed_at DESC
	`, t.ID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var assessments []*models.RiskAssessment
	for rows.Next() {
		var a models.RiskAssessment
		err := rows.Scan(
			&a.ID, &a.TokenID, &a.Probability, &a.Reasoning, &a.Confidence, &a.LLMModel, &a.AssessedAt, &a.CreatedAt,
		)
		if err != nil {
			return nil, err
		}
		assessments = append(assessments, &a)
	}
	return assessments, nil
}

func (r *Repository) List(ctx context.Context, offset, limit int, search string) ([]*models.Token, int, error) {
	var query string
	var countQuery string
	var args []interface{}

	if search != "" {
		query = `
			SELECT id, address, chain_id, deployer, deployed_at, has_unlimited_mint, has_blacklist, has_tax, liquidity_locked, top_holder_concentration, created_at, updated_at
			FROM tokens
			WHERE LOWER(address) LIKE LOWER($1)
			ORDER BY created_at DESC
			LIMIT $2 OFFSET $3
		`
		countQuery = `
			SELECT COUNT(*) FROM tokens
			WHERE LOWER(address) LIKE LOWER($1)
		`
		args = append(args, "%"+search+"%", limit, offset)
	} else {
		query = `
			SELECT id, address, chain_id, deployer, deployed_at, has_unlimited_mint, has_blacklist, has_tax, liquidity_locked, top_holder_concentration, created_at, updated_at
			FROM tokens
			ORDER BY created_at DESC
			LIMIT $1 OFFSET $2
		`
		countQuery = `
			SELECT COUNT(*) FROM tokens
		`
		args = append(args, limit, offset)
	}

	var total int
	var countErr error
	if search != "" {
		countErr = r.pool.QueryRow(ctx, countQuery, "%"+search+"%").Scan(&total)
	} else {
		countErr = r.pool.QueryRow(ctx, countQuery).Scan(&total)
	}
	if countErr != nil {
		return nil, 0, countErr
	}

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var tokens []*models.Token
	for rows.Next() {
		var t models.Token
		err := rows.Scan(
			&t.ID, &t.Address, &t.ChainID, &t.Deployer, &t.DeployedAt,
			&t.HasUnlimitedMint, &t.HasBlacklist, &t.HasTax, &t.LiquidityLocked,
			&t.TopHolderConcentration, &t.CreatedAt, &t.UpdatedAt,
		)
		if err != nil {
			return nil, 0, err
		}
		tokens = append(tokens, &t)
	}
	return tokens, total, nil
}

func (r *Repository) FindLatest(ctx context.Context, limit int) ([]*models.Token, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT id, address, chain_id, deployer, deployed_at, has_unlimited_mint, has_blacklist, has_tax, liquidity_locked, top_holder_concentration, created_at, updated_at
		FROM tokens
		ORDER BY created_at DESC
		LIMIT $1
	`, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var tokens []*models.Token
	for rows.Next() {
		var t models.Token
		err := rows.Scan(
			&t.ID, &t.Address, &t.ChainID, &t.Deployer, &t.DeployedAt,
			&t.HasUnlimitedMint, &t.HasBlacklist, &t.HasTax, &t.LiquidityLocked,
			&t.TopHolderConcentration, &t.CreatedAt, &t.UpdatedAt,
		)
		if err != nil {
			return nil, err
		}
		tokens = append(tokens, &t)
	}
	return tokens, nil
}
