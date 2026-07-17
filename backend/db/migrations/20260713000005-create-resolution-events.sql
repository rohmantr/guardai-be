CREATE TABLE IF NOT EXISTS resolution_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pool_id UUID NOT NULL UNIQUE REFERENCES prediction_pools(id) ON DELETE CASCADE,
    liquidity_pulled BOOLEAN NOT NULL,
    winning_side VARCHAR(3) NOT NULL CHECK (winning_side IN ('YES', 'NO')),
    tx_hash VARCHAR(66) NOT NULL,
    resolved_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
