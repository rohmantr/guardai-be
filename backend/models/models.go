package models

import (
	"time"
)

type Token struct {
	Address     string    `json:"address" db:"address"`
	Name        string    `json:"name" db:"name"`
	Symbol      string    `json:"symbol" db:"symbol"`
	Decimals    int       `json:"decimals" db:"decimals"`
	TotalSupply string    `json:"total_supply" db:"total_supply"`
	CreatedAt   time.Time `json:"created_at" db:"created_at"`
}

type RiskAssessment struct {
	ID           string    `json:"id" db:"id"`
	TokenAddress string    `json:"token_address" db:"token_address"`
	ScannedAt    time.Time `json:"scanned_at" db:"scanned_at"`
	Score        int       `json:"score" db:"score"`
	Details      string    `json:"details" db:"details"`
}

type PredictionPool struct {
	ID            string     `json:"id" db:"id"`
	TokenAddress  string     `json:"token_address" db:"token_address"`
	Status        string     `json:"status" db:"status"` // E.g., OPEN, RESOLVED, CANCELLED
	YesPoolAmount string     `json:"yes_pool_amount" db:"yes_pool_amount"`
	NoPoolAmount  string     `json:"no_pool_amount" db:"no_pool_amount"`
	CreatedAt     time.Time  `json:"created_at" db:"created_at"`
	ResolvedAt    *time.Time `json:"resolved_at,omitempty" db:"resolved_at"`
}

type Position struct {
	ID          string    `json:"id" db:"id"`
	PoolID      string    `json:"pool_id" db:"pool_id"`
	UserAddress string    `json:"user_address" db:"user_address"`
	Prediction  string    `json:"prediction" db:"prediction"` // YES / NO
	Amount      string    `json:"amount" db:"amount"`
	PurchasedAt time.Time `json:"purchased_at" db:"purchased_at"`
}

type ResolutionEvent struct {
	ID            string    `json:"id" db:"id"`
	PoolID        string    `json:"pool_id" db:"pool_id"`
	OracleAddress string    `json:"oracle_address" db:"oracle_address"`
	Outcome       string    `json:"outcome" db:"outcome"` // YES / NO
	ResolvedAt    time.Time `json:"resolved_at" db:"resolved_at"`
}

type Attestation struct {
	ID             string    `json:"id" db:"id"`
	PoolID         string    `json:"pool_id" db:"pool_id"`
	SchemaUID      string    `json:"schema_uid" db:"schema_uid"`
	AttestationUID string    `json:"attestation_uid" db:"attestation_uid"`
	Recipient      string    `json:"recipient" db:"recipient"`
	AttestedAt     time.Time `json:"attested_at" db:"attested_at"`
}
