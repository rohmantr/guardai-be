# Task-004: OracleAdapter Contract

**Prioritas:** P0
**Dependencies:** —
**Module:** contracts/src/oracle/

---

## Objective

Buat kontrak `OracleAdapter.sol` — satu-satunya entry point untuk memicu settlement PredictionPool. Membaca event liquidity-pull dari chain dan mengirim data resolusi.

## Specification

Lihat `docs/specifications/smart-contract-api.md` → OracleAdapter section.

### Interface

```solidity
function reportLiquidityPull(bytes32 poolId, address tokenAddress, bytes calldata proof) external onlyOwner;
function isResolved(bytes32 poolId) external view returns (bool);
function getResolutionData(bytes32 poolId) external view returns (ResolutionData memory);
```

### State

```solidity
struct ResolutionData {
  bool liquidityPulled;
  uint256 timestamp;
  bytes32 txHash;
}
```

### Design Notes

- **Trusted source:** Hanya owner/trusted relayer yang bisa submit data (MVP: manual)
- **Proof:** `bytes calldata proof` untuk future oracle verification (MVP: diabaikan)
- **One-time:** Pool hanya bisa di-resolve sekali

### Files to Create

| File | Path |
|------|------|
| Contract | `contracts/src/oracle/OracleAdapter.sol` |
| Interface | `contracts/src/interfaces/IOracleAdapter.sol` |
| Unit test | `contracts/test/OracleAdapter.t.sol` |

### Acceptance Criteria

- [ ] `reportLiquidityPull` records resolution data for pool
- [ ] Same pool cannot be resolved twice
- [ ] `isResolved` returns correct state
- [ ] `getResolutionData` returns correct data
- [ ] Only owner can report
- [ ] Events emitted: `LiquidityPullReported`, `OracleUpdated`
- [ ] Forge build + test passes
