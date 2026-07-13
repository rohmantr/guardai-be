# Task-005: SettlementManager Contract

**Prioritas:** P0
**Dependencies:** 001 (PredictionPool), 004 (OracleAdapter)
**Module:** contracts/src/settlement/

---

## Objective

Buat kontrak `SettlementManager.sol` yang mengatur jadwal settlement dan memastikan finality — menjembatani OracleAdapter ke PredictionPool.

## Specification

Lihat `docs/specifications/smart-contract-api.md` → SettlementManager section.

### Interface

```solidity
function scheduleSettlement(bytes32 poolId, uint256 deadline) external onlyOwner;
function executeSettlement(bytes32 poolId, bool outcome) external onlyOracle;
function getSettlementStatus(bytes32 poolId) external view returns (SettlementStatus);
```

### Design Notes

- **Two-step flow:** OracleAdapter → SettlementManager.executeSettlement → PredictionPool.settle
- **Deadline enforcement:** Tidak bisa execute settlement sebelum deadline
- **Finality:** Status settlement bersifat final setelah executed

### Files to Create

| File | Path |
|------|------|
| Contract | `contracts/src/settlement/SettlementManager.sol` |
| Interface | `contracts/src/interfaces/ISettlementManager.sol` |
| Unit test | `contracts/test/SettlementManager.t.sol` |

### Integration Test

Buat test yang mensimulasikan flow lengkap:
1. OracleAdapter report liquidity pull
2. SettlementManager execute settlement
3. PredictionPool settle
4. User claim payout

### Acceptance Criteria

- [ ] `scheduleSettlement` sets deadline for pool
- [ ] `executeSettlement` calls PredictionPool.settle correctly
- [ ] Cannot execute before deadline
- [ ] Cannot execute twice
- [ ] Only OracleAdapter can execute
- [ ] Integration test: end-to-end flow passes
- [ ] Forge build + test passes
