CREATE TABLE IF NOT EXISTS tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    address VARCHAR(42) NOT NULL UNIQUE,
    chain_id INTEGER NOT NULL DEFAULT 8453,
    deployer VARCHAR(42) NOT NULL,
    deployed_at TIMESTAMPTZ NOT NULL,
    has_unlimited_mint BOOLEAN DEFAULT NULL,
    has_blacklist BOOLEAN DEFAULT NULL,
    has_tax BOOLEAN DEFAULT NULL,
    liquidity_locked BOOLEAN DEFAULT NULL,
    top_holder_concentration DECIMAL(5,4) DEFAULT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_tokens_address_chain_id ON tokens (chain_id, address);
CREATE INDEX IF NOT EXISTS idx_tokens_deployed_at_desc ON tokens (deployed_at DESC);
