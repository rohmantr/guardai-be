CREATE TABLE IF NOT EXISTS risk_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    token_id UUID NOT NULL REFERENCES tokens(id) ON DELETE CASCADE,
    probability DECIMAL(5,4) NOT NULL,
    reasoning TEXT NOT NULL,
    confidence DECIMAL(5,4) NOT NULL,
    llm_model VARCHAR(50) NOT NULL,
    assessed_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_risk_assessments_token_id ON risk_assessments (token_id);
CREATE INDEX IF NOT EXISTS idx_risk_assessments_token_id_assessed_at ON risk_assessments (token_id, assessed_at DESC);
