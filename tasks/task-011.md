# Task-011: Prediction Module

**Prioritas:** P0
**Dependencies:** 010 (Assessment + AI Agent)
**Module:** src/modules/prediction/

---

## Objective

Buat module prediction — manage prediction pools dan positions. Termasuk worker untuk settlement.

## Specification

Lihat:
- `docs/architecture/backend.md` — module structure
- `docs/architecture/api-spec.md` — pool + position endpoints
- `docs/architecture/events.md` — domain events
- `docs/architecture/state-machine.md` — pool lifecycle

### Components

#### Controller

```typescript
GET    /api/v1/pools                     // List pools (active, resolved)
GET    /api/v1/pools/:id                 // Pool detail (odds, volume)
POST   /api/v1/pools/:id/positions       // Buy position (YES/NO)
GET    /api/v1/positions                 // User's positions
GET    /api/v1/positions/:id             // Position detail
```

#### Service

```typescript
class PredictionService {
  async createPool(assessmentId: string): Promise<PredictionPool>
  async buyPosition(poolId: string, user: string, side: Side, amount: bigint): Promise<Position>
  async getPool(id: string): Promise<PoolDetail>
  async getUserPositions(user: string): Promise<Position[]>
}
```

#### Pool Factory

```typescript
class PoolFactory {
  // Deploy PredictionPool contract via viem
  async deployPool(tokenAddress: string, probability: number): Promise<string>
}
```

#### Workers

```typescript
// workers/token-detector.ts — periodic scan for new tokens
// workers/settlement.ts — check expired pools, trigger settlement
// workers/attestation.ts — submit attestation to EAS after settlement
```

### Domain Events

```typescript
// common/events/domain-events.ts
interface DomainEvent<T> {
  id: string;
  type: string;
  timestamp: string;
  data: T;
  correlationId: string;
}
```

### Files to Create

| File | Path |
|------|------|
| Controller | `src/modules/prediction/controllers/pool.controller.ts` |
| Service | `src/modules/prediction/services/prediction.service.ts` |
| Pool Factory | `src/modules/prediction/services/pool-factory.ts` |
| Repositories (2) | `src/modules/prediction/repositories/*.ts` |
| Entities (2) | `src/modules/prediction/entities/*.ts` |
| Routes | `src/modules/prediction/prediction.routes.ts` |
| Workers (3) | `src/workers/token-detector.ts`, `settlement.ts`, `attestation.ts` |
| Domain events | `src/common/events/domain-events.ts` |
| Unit test | `src/modules/prediction/prediction.service.spec.ts` |

### Acceptance Criteria

- [ ] Pool can be created from assessment
- [ ] `POST /pools/:id/positions` records position
- [ ] Token detector worker polls and creates assessments
- [ ] Settlement worker expires pools after deadline
- [ ] Events emitted on state changes
- [ ] `bun test` passes
