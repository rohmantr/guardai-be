# Task-009: Token Module

**Prioritas:** P0
**Dependencies:** 008 (Database schema)
**Module:** src/modules/token/

---

## Objective

Buat module token — deteksi token baru di Base dan baca data on-chain (bytecode, liquidity, holder distribution).

## Specification

Lihat:
- `docs/architecture/ai-agent.md` → Data Collection
- `docs/architecture/api-spec.md` → Token endpoints

### Components

#### Controller

```typescript
GET    /api/v1/tokens                    // List tokens (paginated, filterable)
GET    /api/v1/tokens/:address           // Detail token + latest assessment
GET    /api/v1/tokens/:address/assessments  // Assessment history
```

#### Service

```typescript
class TokenService {
  async detectNewTokens(): Promise<Token[]>
  async readContractData(address: string): Promise<ContractData>
  async getToken(address: string): Promise<Token>
  async listTokens(filter: TokenFilter): Promise<PaginatedResult<Token>>
}
```

#### Repository

```typescript
class TokenRepository {
  async findByAddress(address: string): Promise<Token | null>
  async save(token: Token): Promise<Token>
  async findLatest(limit: number): Promise<Token[]>
}
```

### On-Chain Reading

Implementasi menggunakan `viem`:

```typescript
// Read bytecode
const bytecode = await client.getBytecode({ address });

// Check for function selectors
const RISK_SELECTORS = [
  '0x' + keccak256('mint(address,uint256)').slice(0, 10),  // unlimited mint
  '0x' + keccak256('blacklist(address)').slice(0, 10),     // blacklist
];
```

### Files to Create

| File | Path |
|------|------|
| Controller | `src/modules/token/controllers/token.controller.ts` |
| Service | `src/modules/token/services/token.service.ts` |
| Repository | `src/modules/token/repositories/token.repository.ts` |
| Entity | `src/modules/token/entities/token.entity.ts` |
| Routes | `src/modules/token/token.routes.ts` |
| Unit test | `src/modules/token/token.service.spec.ts` |

### Acceptance Criteria

- [ ] `GET /api/v1/tokens` returns paginated list
- [ ] `GET /api/v1/tokens/:address` returns token with assessment
- [ ] Bytecode reader detects known risk function selectors
- [ ] Error handling for invalid addresses
- [ ] `bun test` passes
