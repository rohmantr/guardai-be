# Treasury Contract — Design Spec

**Date:** 2026-07-17
**Project:** Rug Radar
**Status:** Approved

## Overview

Treasury is a vault contract that manages protocol funds — accepts deposits from PredictionPools, performs payouts to winners, and allows the owner to withdraw accumulated fees.

## Interface

```solidity
function deposit(bytes32 poolId) external payable;
function payout(address winner, uint256 amount) external;
function withdrawFees(address to, uint256 amount) external;
function getBalance(bytes32 poolId) external view returns (uint256);
```

## Architecture

- **Balance tracking per pool:** `mapping(bytes32 => uint256) private _poolBalances`
- **Fee accumulation:** `uint256 private _accumulatedFees`
- **Pool registry:** `mapping(address => bool) public registeredPools` — only these can call `payout`
- **Fee basis points:** `uint256 public feeBps`, set by owner, capped at 1000 (10%)

## Flow

### Deposit
1. ETH received from pool deployer
2. Fee calculated: `fee = (msg.value * feeBps) / 10000`
3. `_accumulatedFees += fee`
4. `_poolBalances[poolId] += msg.value - fee`
5. Emit `Deposited(poolId, msg.value - fee)`

### Payout
1. Only registered pool can call
2. Checks `_poolBalances[poolId] >= amount`
3. Transfers ETH to winner
4. Deducts from pool balance
5. Emit `PayoutSent(poolId, winner, amount)`

### Withdraw Fees
1. Only owner
2. Checks `_accumulatedFees >= amount`
3. Transfers ETH to `to`
4. Deducts from accumulated fees
5. Emit `FeesWithdrawn(to, amount)`

## OpenZeppelin Usage

- `Ownable` (not 2Step — Treasury is simple, onlyPredictionPoolFactory )
  `ponytail:` Upgrade to Ownable2Step if ownership transfer risk becomes relevant.

## Files

| File | Path |
|------|------|
| Interface | `contracts/src/interfaces/ITreasury.sol` |
| Contract | `contracts/src/core/Treasury.sol` |
| Unit test | `contracts/test/Treasury.t.sol` |

## Security

- CEI pattern: state update before ETH transfer
- ReentrancyGuard on `payout` and `withdrawFees`
- Custom errors: `InsufficientBalance`, `TransferFailed`, `UnauthorizedPool`, `FeeTooHigh`
- No `tx.origin`, no `delegatecall`, no `selfdestruct`

## Acceptance Criteria

- [ ] `deposit` accepts ETH and records pool balance
- [ ] `payout` can only be called by registered pool
- [ ] `withdrawFees` only callable by owner
- [ ] Balance tracking is accurate per pool
- [ ] Fee calculation is correct
- [ ] Forge build + test passes
