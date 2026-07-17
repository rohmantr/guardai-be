CREATE TABLE IF NOT EXISTS positions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pool_id UUID NOT NULL REFERENCES prediction_pools(id) ON DELETE CASCADE,
    user_address VARCHAR(42) NOT NULL,
    side VARCHAR(3) NOT NULL CHECK (side IN ('YES', 'NO')),
    amount NUMERIC(40,0) NOT NULL CHECK (amount > 0),
    claimed BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_positions_pool_id_user_address ON positions (pool_id, user_address);
CREATE INDEX IF NOT EXISTS idx_positions_user_address ON positions (user_address);
CREATE INDEX IF NOT EXISTS idx_positions_pool_id ON positions (pool_id);
