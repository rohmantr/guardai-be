# Task-001: PredictionPool Contract

**Prioritas:** P0
**Dependencies:** —
**Module:** contracts/src/core/

---

## Objective

Buat kontrak `PredictionPool.sol` — inti sistem yang menerima posisi YES/NO dari trader dan melakukan settlement otomatis berdasarkan input dari OracleAdapter.

## Specification

Lihat `docs/specifications/smart-contract-api.md` → PredictionPool section.

### Interface

```solidity
function buyPosition(Side side, uint256 amount) external payable;
function settle(bool liquidityPulled) external onlyOracleAdapter;
function claim(address user) external returns (uint256 payout);
function getPoolInfo() external view returns (PoolInfo memory);
function getPosition(address user) external view returns (Position memory);
function isActive() external view returns (bool);
function isResolved() external view returns (bool);
```

### State

```solidity
enum Side { YES, NO }
enum PoolStatus { Pending, Active, Resolved, Expired }

struct PoolInfo {
  bytes32 poolId;
  address tokenAddress;
  uint256 yesPool;
  uint256 noPool;
  PoolStatus status;
  uint256 deadline;
  Side winningSide;
}
```

### Access Control

- **Owner** (Ownable2Step): deploy, emergency pause
- **OracleAdapter** (modifier `onlyOracleAdapter`): call `settle()`

### Events

```
PoolCreated, PositionPurchased, PoolResolved, ClaimExecuted
```

### Security

- ReentrancyGuard di `buyPosition` dan `claim`
- Checks-Effects-Interactions di `claim`
- Pausable untuk emergency stop
- Deadline check: positions only before deadline, settlement only after deadline

### Files to Create

| File | Path |
|------|------|
| Contract | `contracts/src/core/PredictionPool.sol` |
| Interface | `contracts/src/interfaces/IPredictionPool.sol` |
| Unit test | `contracts/test/PredictionPool.t.sol` |

### Acceptance Criteria

- [ ] `buyPosition` accepts ETH and records position
- [ ] Multiple positions from same user are aggregated
- [ ] `settle` can only be called by OracleAdapter
- [ ] `claim` calculates correct payout proportionally
- [ ] Pool expires after deadline
- [ ] All events emitted correctly
- [ ] Reentrancy protection works (`vm.expectRevert` test)
- [ ] Forge build passes
- [ ] Forge test passes
