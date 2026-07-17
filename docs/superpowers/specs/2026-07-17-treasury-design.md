# Treasury Contract — Design Spec (v2)

**Date:** 2026-07-17 (rev)
**Project:** Rug Radar
**Status:** Approved

## Changelog v1 → v2

| # | Isu | Perbaikan |
|---|---|---|
| 1 | `payout` tidak punya `poolId`, tapi flow butuh itu | Treasury simpan mapping `pool address → poolId`, diturunkan dari `msg.sender` |
| 2 | `deposit` tidak terikat ke identitas caller — siapa saja bisa deposit ke `poolId` sembarang | `deposit()` tidak lagi menerima `poolId` sbg parameter; diambil dari registrasi pool pemanggil |
| 3 | Tidak ada fungsi untuk mengisi `registeredPools` | Ditambahkan `registerPool(address, bytes32)`, `onlyOwner` |
| 4 | `feeBps` tidak punya setter | Ditambahkan `setFeeBps(uint256)`, `onlyOwner`, capped 1000 |
| 5 | Mekanisme transfer ETH tidak dispesifikasikan | Pakai `call{value}("")` |
| 6 | Tidak ada zero-address check | Ditambahkan |
| 7 | `Ownable` vs `Ownable2Step` | Pakai `Ownable2Step` dari awal — Treasury pegang dana pool + fee |

## Interface

```solidity
function registerPool(address pool, bytes32 poolId) external;
function deposit() external payable;
function payout(address winner, uint256 amount) external;
function withdrawFees(address to, uint256 amount) external;
function setFeeBps(uint256 newFeeBps) external;
function getBalance(bytes32 poolId) external view returns (uint256);
```

## Architecture

- **Balance tracking per pool:** `mapping(bytes32 => uint256) private _poolBalances`
- **Fee accumulation:** `uint256 private _accumulatedFees`
- **Pool registry:** `mapping(address => bool) public registeredPools`
- **Pool identity binding:** `mapping(address => bytes32) public poolIdOf` — mengikat `msg.sender` ke `poolId`
- **Fee basis points:** `uint256 public feeBps`, capped 1000 (10%)

## Flow

### Register Pool
- Only owner
- Zero-address check
- Set `registeredPools[pool] = true`, `poolIdOf[pool] = poolId`
- Emit `PoolRegistered(pool, poolId)`

### Deposit
- Only registered pool (`registeredPools[msg.sender]`)
- `poolId = poolIdOf[msg.sender]`
- Fee: `(msg.value * feeBps) / 10000`
- `_accumulatedFees += fee`, `_poolBalances[poolId] += msg.value - fee`
- Emit `Deposited(poolId, msg.sender, msg.value - fee)`

### Payout
- Only registered pool
- `poolId = poolIdOf[msg.sender]`
- Zero-address check on winner
- CEI: `_poolBalances[poolId] -= amount` then `call{value: amount}("")`
- Emit `PayoutSent(poolId, winner, amount)`

### Withdraw Fees
- Only owner
- Zero-address check
- CEI: `_accumulatedFees -= amount` then `call{value: amount}("")`
- Emit `FeesWithdrawn(to, amount)`

### Set Fee Bps
- Only owner
- Revert if > 1000
- Emit `FeeUpdated(newFeeBps)`

## OpenZeppelin

- `Ownable2Step`
- `ReentrancyGuard` (on payout, withdrawFees)

## Events

```solidity
event PoolRegistered(address indexed pool, bytes32 indexed poolId);
event Deposited(bytes32 indexed poolId, address indexed pool, uint256 amount);
event PayoutSent(bytes32 indexed poolId, address indexed winner, uint256 amount);
event FeesWithdrawn(address indexed to, uint256 amount);
event FeeUpdated(uint256 newFeeBps);
```

## Errors

```solidity
error InsufficientBalance();
error TransferFailed();
error UnauthorizedPool();
error FeeTooHigh();
error ZeroAddress();
error PoolAlreadyRegistered();
error PoolNotRegistered();
```

## Files

| File | Path |
|------|------|
| Interface | `contracts/src/interfaces/ITreasury.sol` |
| Contract | `contracts/src/core/Treasury.sol` |
| Unit test | `contracts/test/Treasury.t.sol` |

## Security

- CEI pattern on all fund-moving functions
- ReentrancyGuard on payout & withdrawFees
- Zero-address checks
- `call{value}("")` for ETH transfer (not `.transfer()`/`.send()`)
- No `receive()`/`fallback()` — stray ETH reverts
- Invariant: `address(this).balance == sum(_poolBalances) + _accumulatedFees`

## Acceptance Criteria

- [ ] `registerPool` only owner, bind `poolId` to `pool`
- [ ] `deposit` only registered pool; revert for unregistered
- [ ] `deposit` derives `poolId` from `msg.sender`, not external input
- [ ] `payout` only registered pool
- [ ] `payout`/`withdrawFees` revert for address(0)
- [ ] `withdrawFees` only owner
- [ ] `setFeeBps` revert if > 1000
- [ ] Balance tracking accurate per pool
- [ ] Fee calculation correct
- [ ] Invariant `balance == sum(poolBalances) + fees` holds
- [ ] Forge build + test passes
