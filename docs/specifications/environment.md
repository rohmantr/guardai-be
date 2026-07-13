# Rug Radar — Environment Variables

**Versi:** 1.0
**Tanggal:** 13 Juli 2026

---

## Required Variables

| Variable | Purpose | Example | Security |
|----------|---------|---------|----------|
| `NODE_ENV` | Environment mode | `development` | N/A |
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://user:pass@localhost:5432/rugradar` | **Sensitive** |
| `RPC_URL` | Base RPC endpoint | `https://mainnet.base.org` | Public |
| `LLM_API_KEY` | API key untuk LLM provider | `sk-...` | **Critical** |
| `LLM_MODEL` | Model LLM yang digunakan | `gpt-4o` | N/A |
| `PRIVATE_KEY` | Private key deployer (CI only) | `0x...` | **Critical** |
| `EAS_CONTRACT_ADDRESS` | Alamat EAS contract | `0x...` | Public |

## Optional Variables

| Variable | Purpose | Default | Security |
|----------|---------|---------|----------|
| `PORT` | HTTP server port | `3000` | N/A |
| `REDIS_URL` | Redis connection string | — | Mild |
| `RABBITMQ_URL` | RabbitMQ connection string | — | Mild |
| `API_KEY_SALT` | Salt untuk hashing API key | — | **Sensitive** |
| `LOG_LEVEL` | Logging level | `info` | N/A |
| `CORS_ORIGIN` | Allowed CORS origin | `*` (dev) | N/A |
| `RATE_LIMIT_WINDOW` | Rate limit window (ms) | `60000` | N/A |
| `RATE_LIMIT_MAX` | Max requests per window | `100` | N/A |
| `LLM_TIMEOUT` | LLM request timeout (ms) | `15000` | N/A |
| `LLM_MAX_RETRIES` | LLM retry count | `2` | N/A |
| `TOKEN_SCAN_INTERVAL` | Token detection interval (ms) | `30000` | N/A |
| `SETTLEMENT_WINDOW` | Pool duration (ms) | `86400000` (24h) | N/A |
| `HEALTH_CHECK_PORT` | Health check server port | `3001` | N/A |

## Security Considerations

| Variable | Risk if Exposed | Mitigation |
|----------|----------------|------------|
| `LLM_API_KEY` | Unauthorized LLM usage, cost | Rotate monthly, store in Vault, never log |
| `PRIVATE_KEY` | Full control over deployed contracts | Use KMS / hardware wallet; only in CI secrets |
| `DATABASE_URL` | Full DB access | Restrict IP, use read-only replicas for queries |
| `API_KEY_SALT` | Can forge API keys | Gitignored, generated at setup, never rotate |

## Environment-Specific Configurations

### Development

```bash
NODE_ENV=development
DATABASE_URL=postgresql://dev:dev@localhost:5432/rugradar_dev
RPC_URL=https://sepolia.base.org
LLM_MODEL=gpt-4o-mini      # cheaper for dev
PORT=3000
LOG_LEVEL=debug
```

### Staging

```bash
NODE_ENV=staging
DATABASE_URL=postgresql://app:${DB_PASS}@staging-db:5432/rugradar_staging
RPC_URL=https://sepolia.base.org
LLM_MODEL=gpt-4o
PORT=3000
LOG_LEVEL=info
```

### Production

```bash
NODE_ENV=production
DATABASE_URL=postgresql://app:${DB_PASS}@prod-db:5432/rugradar
RPC_URL=https://mainnet.base.org
LLM_MODEL=gpt-4o
PORT=3000
LOG_LEVEL=info
RATE_LIMIT_MAX=100
TOKEN_SCAN_INTERVAL=60000
```
