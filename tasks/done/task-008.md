# Task-008: Database Schema + Migrations

**Prioritas:** P0
**Dependencies:** —
**Module:** src/

---

## Objective

Buat database schema dan migration files sesuai `docs/architecture/database.md`, dengan 6 entities: tokens, risk_assessments, prediction_pools, positions, resolution_events, attestations.

## Specification

Lihat `docs/specifications/database-schema.md` untuk detail kolom, tipe, constraints, indexes, cascade rules.

### Entities

```typescript
// src/modules/token/entities/token.entity.ts
// src/modules/assessment/entities/risk-assessment.entity.ts
// src/modules/prediction/entities/prediction-pool.entity.ts
// src/modules/prediction/entities/position.entity.ts
// src/modules/oracle/entities/resolution-event.entity.ts
// src/modules/attestation/entities/attestation.entity.ts
```

### Migration

```sql
— 20260713000001-create-tokens.sql
— 20260713000002-create-risk-assessments.sql
— 20260713000003-create-prediction-pools.sql
— 20260713000004-create-positions.sql
— 20260713000005-create-resolution-events.sql
— 20260713000006-create-attestations.sql
```

### Setup

```bash
# Database
docker compose up -d postgres
```

### Files to Create

| File | Path |
|------|------|
| Entity files (6) | `src/modules/*/entities/*.entity.ts` |
| SQL migrations (6) | `src/migrations/*.sql` |
| DB connection | `src/common/database.ts` |

### Acceptance Criteria

- [ ] All entities match `docs/specifications/database-schema.md`
- [ ] Foreign keys, indexes, and constraints correct
- [ ] Migrations can run cleanly
- [ ] `bun run build` passes
