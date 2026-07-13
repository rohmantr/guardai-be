# Rug Radar — External Integrations

**Versi:** 1.0
**Tanggal:** 13 Juli 2026

---

## 1. Base RPC Integration

**Purpose:** Membaca data on-chain token — bytecode, liquidity status, holder distribution.

### Endpoint

| Environment | URL |
|-------------|-----|
| Development | `https://sepolia.base.org` |
| Staging | `https://sepolia.base.org` |
| Production | `https://mainnet.base.org` |

### Integration Points

| Function | RPC Method | Frequency | Criticality |
|----------|-----------|-----------|-------------|
| Baca bytecode kontrak | `eth_getCode` | Per token baru | High |
| Baca holder distribution | `eth_call` (custom script) | Per token baru | High |
| Baca liquidity pool state | `eth_call` (pair contract) | Per token baru | High |
| Deteksi token baru | `eth_getLogs` (filter deploy events) | Polling 30s | Medium |
| Konfirmasi transaksi | `eth_getTransactionReceipt` | On-demand | High |

### Rate Limits

| Provider | Rate Limit | Strategy |
|----------|-----------|----------|
| Public Base RPC | 10 req/s | Queue + retry |
| Alchemy / QuickNode | 100 req/s | Use in production |

### Failure Handling

- Timeout (>10s) → retry 3x with 1s backoff
- Rate limit (429) → exponential backoff (30s, 60s, 120s)
- All retries exhausted → skip token, retry next cycle

---

## 2. OpenAI Integration

**Purpose:** LLM inference untuk risk assessment.

### Endpoint

```bash
POST https://api.openai.com/v1/chat/completions
```

### Authentication

```http
Authorization: Bearer ${LLM_API_KEY}
```

### Request Format

```json
{
  "model": "gpt-4o",
  "messages": [
    {"role": "system", "content": "You are Rug Radar Risk Assessment Agent..."},
    {"role": "user", "content": "Analyze this token: {...}"}
  ],
  "temperature": 0.0,
  "max_tokens": 200
}
```

### Cost Estimation

| Model | Cost / 1K input tokens | Cost / 1K output tokens | Per Assessment |
|-------|------------------------|------------------------|----------------|
| gpt-4o | $0.0025 | $0.01 | ~$0.003 |
| gpt-4o-mini | $0.00015 | $0.0006 | ~$0.0002 |
| claude-sonnet-4 | $0.003 | $0.015 | ~$0.004 |

### Failure Handling

- Timeout (>15s) → retry 2x with 2s backoff
- 429 (rate limit) → exponential backoff (30s, 60s, 120s)
- 401 (auth) → alert admin, stop all assessments
- 5xx → retry 2x, then fallback

---

## 3. EAS (Ethereum Attestation Service) Integration

**Purpose:** Mencatat hasil settlement sebagai attestation on-chain untuk track record agent.

### Contract Address

| Chain | EAS Contract |
|-------|-------------|
| Base Sepolia | `0x4200000000000000000000000000000000000021` |
| Base Mainnet | `0x4200000000000000000000000000000000000021` |

### Integration Points

| Action | Method | When |
|--------|--------|------|
| Attest result | `EAS.attest()` | After settlement |
| Query attestation | `EAS.getAttestation()` | On-demand |

### Schema

```solidity
struct AttestationData {
  bytes32 poolId;
  address tokenAddress;
  uint256 probability;   // scaled: 7500 = 0.75
  bool predictedOutcome; // true = YES (rug)
  bool actualOutcome;     // true = YES (rug)
  uint256 timestamp;
}
```

### Failure Handling

- Transaction revert → retry 3x
- EAS contract not found → alert (wrong chain?)
- Gas estimation failure → adjust gas limit, retry

---

## 4. Redis Integration

**Purpose:** Queue broker, cache.

### Connection

```bash
redis://localhost:6379
```

### Usage

| Purpose | Data Type | TTL |
|---------|-----------|-----|
| Token detection queue | List (LPUSH/BRPOP) | — |
| Assessment queue | List | — |
| Settlement queue | List | — |
| Rate limiter counters | Sorted Set | Window size |
| Cache: token data | String | 5 minutes |
| Cache: pool data | String | 30 seconds |

### Failure Handling

- Connection error → retry 3x with backoff
- Persistent failure → graceful degradation (queue in-memory, alert admin)

### ponytail: clustering — Redis Cluster untuk HA, add when we have >500 req/s

---

## 5. PostgreSQL Integration

**Purpose:** Primary database.

### Connection

```
postgresql://user:password@host:5432/rugradar
```

### Connection Pool

| Setting | Development | Production |
|---------|-------------|------------|
| Min connections | 2 | 5 |
| Max connections | 10 | 25 |
| Idle timeout | 30s | 60s |
| Connection timeout | 5s | 10s |

### ORM

- **Tool:** TypeORM
- **Synchronize:** `false` in production (use migrations)

### Failure Handling

- Connection loss → retry with exponential backoff
- Connection pool exhaustion → return 503, alert
- Transaction error → rollback, log, retry (idempotent operations only)

---

## 6. Future Oracle Integrations

*(Not in MVP — documented for roadmap)*

| Oracle | Purpose | When |
|--------|---------|------|
| **Pyth Network** | Price data untuk liquidity USD value | Post-MVP |
| **Chainlink Automation** | Trigger settlement if deadline approaches | Post-MVP |
| **Uniswap V3 Subgraph** | Alternative data source for liquidity state | Post-MVP |
| **DEXX** | Additional holder data source | Post-MVP |

### ponytail: multi-oracle consensus — ketika ada >2 oracle provider, add weighted consensus layer
