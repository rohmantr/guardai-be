package models

import (
	"time"
)

type Token struct {
	ID                     string    `json:"id" db:"id"`
	Address                string    `json:"address" db:"address"`
	ChainID                int       `json:"chain_id" db:"chain_id"`
	Deployer               string    `json:"deployer" db:"deployer"`
	DeployedAt             time.Time `json:"deployed_at" db:"deployed_at"`
	HasUnlimitedMint       *bool     `json:"has_unlimited_mint" db:"has_unlimited_mint"`
	HasBlacklist           *bool     `json:"has_blacklist" db:"has_blacklist"`
	HasTax                 *bool     `json:"has_tax" db:"has_tax"`
	LiquidityLocked        *bool     `json:"liquidity_locked" db:"liquidity_locked"`
	TopHolderConcentration *float64  `json:"top_holder_concentration" db:"top_holder_concentration"`
	CreatedAt              time.Time `json:"created_at" db:"created_at"`
	UpdatedAt              time.Time `json:"updated_at" db:"updated_at"`
}

type RiskAssessment struct {
	ID          string    `json:"id" db:"id"`
	TokenID     string    `json:"token_id" db:"token_id"`
	Probability float64   `json:"probability" db:"probability"`
	Reasoning   string    `json:"reasoning" db:"reasoning"`
	Confidence  float64   `json:"confidence" db:"confidence"`
	LLMModel    string    `json:"llm_model" db:"llm_model"`
	Source      string    `json:"source" db:"source"`
	RawResponse *string   `json:"raw_response,omitempty" db:"raw_response"`
	AssessedAt  time.Time `json:"assessed_at" db:"assessed_at"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
}

type PredictionPool struct {
	ID              string     `json:"id" db:"id"`
	TokenID         string     `json:"token_id" db:"token_id"`
	AssessmentID    string     `json:"assessment_id" db:"assessment_id"`
	ContractAddress string     `json:"contract_address" db:"contract_address"`
	YesPoolAmount   string     `json:"yes_pool_amount" db:"yes_pool_amount"`
	NoPoolAmount    string     `json:"no_pool_amount" db:"no_pool_amount"`
	Status          string     `json:"status" db:"status"`
	Deadline        time.Time  `json:"deadline" db:"deadline"`
	CreatedAt       time.Time  `json:"created_at" db:"created_at"`
	ResolvedAt      *time.Time `json:"resolved_at,omitempty" db:"resolved_at"`
}

type Position struct {
	ID          string    `json:"id" db:"id"`
	PoolID      string    `json:"pool_id" db:"pool_id"`
	UserAddress string    `json:"user_address" db:"user_address"`
	Side        string    `json:"side" db:"side"`
	Amount      string    `json:"amount" db:"amount"`
	Claimed     bool      `json:"claimed" db:"claimed"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
}

type ResolutionEvent struct {
	ID              string    `json:"id" db:"id"`
	PoolID          string    `json:"pool_id" db:"pool_id"`
	LiquidityPulled bool      `json:"liquidity_pulled" db:"liquidity_pulled"`
	WinningSide     string    `json:"winning_side" db:"winning_side"`
	TxHash          string    `json:"tx_hash" db:"tx_hash"`
	ResolvedAt      time.Time `json:"resolved_at" db:"resolved_at"`
}

type Attestation struct {
	ID               string    `json:"id" db:"id"`
	PoolID           string    `json:"pool_id" db:"pool_id"`
	EASUID           string    `json:"eas_uid" db:"eas_uid"`
	PredictedOutcome bool      `json:"predicted_outcome" db:"predicted_outcome"`
	ActualOutcome    bool      `json:"actual_outcome" db:"actual_outcome"`
	AttestedAt       time.Time `json:"attested_at" db:"attested_at"`
}
