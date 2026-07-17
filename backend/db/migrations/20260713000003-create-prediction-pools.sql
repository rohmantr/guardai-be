CREATE TABLE IF NOT EXISTS prediction_pools (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token_id UUID NOT NULL REFERENCES tokens(id) ON DELETE CASCADE,
    assessment_id UUID NOT NULL REFERENCES risk_assessments(id) ON DELETE RESTRICT,
    contract_address VARCHAR(42) NOT NULL UNIQUE,
    yes_pool_amount NUMERIC(40,0) NOT NULL DEFAULT 0,
    no_pool_amount NUMERIC(40,0) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'resolved', 'expired')),
    deadline TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_at TIMESTAMPTZ DEFAULT NULL
);

CREATE INDEX IF NOT EXISTS idx_prediction_pools_token_id ON prediction_pools (token_id);
CREATE INDEX IF NOT EXISTS idx_prediction_pools_status ON prediction_pools (status);
CREATE INDEX IF NOT EXISTS idx_prediction_pools_deadline ON prediction_pools (deadline);
