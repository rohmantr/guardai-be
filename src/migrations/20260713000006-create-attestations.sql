CREATE TABLE IF NOT EXISTS attestations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pool_id UUID NOT NULL UNIQUE REFERENCES resolution_events(pool_id) ON DELETE CASCADE,
    eas_uid VARCHAR(66) NOT NULL UNIQUE,
    predicted_outcome BOOLEAN NOT NULL,
    actual_outcome BOOLEAN NOT NULL,
    attested_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
