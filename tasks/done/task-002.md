# Task-002: Treasury Contract

**Prioritas:** P0
**Dependencies:** —
**Module:** contracts/src/core/

---

## Objective

Buat kontrak `Treasury.sol` yang mengelola dana protokol — menerima deposit dari PredictionPool, melakukan payout ke pemenang, dan memungkinkan owner menarik fee.

## Specification

Lihat `docs/specifications/smart-contract-api.md` → Treasury section.

### Interface

```solidity
function deposit(bytes32 poolId) external payable;
function payout(address winner, uint256 amount) external onlyPool;
function withdrawFees(address to, uint256 amount) external onlyOwner;
function getBalance(bytes32 poolId) external view returns (uint256);
```

### Design Notes

- **Pool-based accounting:** Treasury melacak balance per `poolId`
- **onlyPool modifier:** Hanya PredictionPool terdaftar yang bisa call `payout`
- **Pull over push:** `payout` hanya dipanggil oleh PredictionPool saat `claim`
- **Fee:** % dari setiap deposit (konfigurable oleh owner)

### Files to Create

| File | Path |
|------|------|
| Contract | `contracts/src/core/Treasury.sol` |
| Interface | `contracts/src/interfaces/ITreasury.sol` |
| Unit test | `contracts/test/Treasury.t.sol` |

### Acceptance Criteria

- [ ] `deposit` accepts ETH and records pool balance
- [ ] `payout` can only be called by registered pool
- [ ] `withdrawFees` only callable by owner
- [ ] Balance tracking is accurate per pool
- [ ] Fee calculation is correct
- [ ] Forge build + test passes
