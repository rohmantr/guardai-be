# Rug Radar — Smart Contract API Specification

**Versi:** 1.0
**Tanggal:** 13 Juli 2026

---

## 1. PredictionPool

Kontrak utama untuk setiap token baru. Satu instance per token.

### Functions

#### `buyPosition`

```solidity
function buyPosition(Side side, uint256 amount) external payable;
```

| Parameter | Tipe | Deskripsi |
|-----------|------|-----------|
| `side` | `Side` (enum: YES=0, NO=1) | Posisi yang dibeli |
| `amount` | `uint256` | Jumlah posisi (dalam wei) |

- **Access:** Public,任何人都可以调用
- **Reverts:** `PoolNotActive()`, `PoolExpired()`, `InsufficientPayment()`, `PositionTooSmall()`
- **Emits:** `PositionPurchased(poolId, msg.sender, side, amount)`

#### `settle`

```solidity
function settle(bool liquidityPulled) external onlyOracleAdapter;
```

| Parameter | Tipe | Deskripsi |
|-----------|------|-----------|
| `liquidityPulled` | `bool` | `true` = YES menang, `false` = NO menang |

- **Access:** Hanya OracleAdapter (via modifier)
- **Reverts:** `PoolAlreadyResolved()`, `PoolNotActive()`, `NotOracleAdapter()`
- **Emits:** `PoolResolved(poolId, winningSide, totalYes, totalNo)`

#### `claim`

```solidity
function claim(address user) external returns (uint256 payout);
```

| Parameter | Tipe | Deskripsi |
|-----------|------|-----------|
| `user` | `address` | Alamat yang mengklaim payout |

| Return | Tipe | Deskripsi |
|--------|------|-----------|
| `payout` | `uint256` | Jumlah payout dalam wei |

- **Access:** Public
- **Reverts:** `PoolNotResolved()`, `NothingToClaim()`, `AlreadyClaimed()`
- **Emits:** `ClaimExecuted(poolId, user, payout)`

#### Getters

```solidity
function getPoolInfo() external view returns (PoolInfo memory);
function getPosition(address user) external view returns (Position memory);
function isActive() external view returns (bool);
function isResolved() external view returns (bool);
function getYesPool() external view returns (uint256);
function getNoPool() external view returns (uint256);
```

### State Variables

| Variable | Tipe | Visibility |
|----------|------|------------|
| `poolId` | `bytes32` | `public` |
| `tokenAddress` | `address` | `public` |
| `yesPool` | `uint256` | `internal` |
| `noPool` | `uint256` | `internal` |
| `status` | `PoolStatus` (enum) | `internal` |
| `deadline` | `uint256` | `public` |
| `winningSide` | `Side` | `internal` |
| `oracleAdapter` | `address` | `internal` |

### Events

```solidity
event PoolCreated(bytes32 indexed poolId, address indexed token, uint256 deadline);
event PositionPurchased(bytes32 indexed poolId, address indexed user, Side side, uint256 amount);
event PoolResolved(bytes32 indexed poolId, Side winningSide, uint256 totalYes, uint256 totalNo);
event ClaimExecuted(bytes32 indexed poolId, address indexed user, uint256 payout);
```

### Custom Errors

```solidity
error PoolNotActive();
error PoolExpired();
error PoolAlreadyResolved();
error NotOracleAdapter();
error InsufficientPayment();
error PositionTooSmall();
error NothingToClaim();
error AlreadyClaimed();
error DeadlineNotReached();
```

### Access Control

- **Owner** (Ownable2Step): Deploy pool, set OracleAdapter, emergency pause
- **OracleAdapter** (via modifier `onlyOracleAdapter`): Call `settle()`

---

## 2. SettlementManager

### Functions

```solidity
function scheduleSettlement(bytes32 poolId, uint256 deadline) external onlyOwner;
function executeSettlement(bytes32 poolId, bool outcome) external onlyOracle;
function getSettlementStatus(bytes32 poolId) external view returns (SettlementStatus);
```

### Events

```solidity
event SettlementScheduled(bytes32 indexed poolId, uint256 deadline);
event SettlementExecuted(bytes32 indexed poolId, bool outcome);
event SettlementFailed(bytes32 indexed poolId, string reason);
```

### Custom Errors

```solidity
error SettlementAlreadyScheduled();
error SettlementNotReady();
error InvalidOracleData();
error PoolNotFound();
```

---

## 3. OracleAdapter

### Functions

```solidity
function reportLiquidityPull(bytes32 poolId, address tokenAddress, bytes calldata proof) external onlyOwner;
function isResolved(bytes32 poolId) external view returns (bool);
function getResolutionData(bytes32 poolId) external view returns (ResolutionData memory);
```

### Events

```solidity
event LiquidityPullReported(bytes32 indexed poolId, address indexed token, uint256 timestamp);
event OracleUpdated(address indexed oldOracle, address indexed newOracle);
```

### Custom Errors

```solidity
error AlreadyResolved();
error InvalidProof();
error NotTrustedRelayer();
error PoolExpired();
```

---

## 4. Treasury

### Functions

```solidity
function deposit(bytes32 poolId) external payable;
function payout(address winner, uint256 amount) external onlyPool;
function withdrawFees(address to, uint256 amount) external onlyOwner;
function getBalance(bytes32 poolId) external view returns (uint256);
```

### Events

```solidity
event Deposited(bytes32 indexed poolId, uint256 amount);
event PayoutSent(bytes32 indexed poolId, address indexed winner, uint256 amount);
event FeesWithdrawn(address indexed to, uint256 amount);
```

### Custom Errors

```solidity
error InsufficientBalance();
error TransferFailed();
error UnauthorizedPool();
```

---

## 5. RiskRegistry

### Functions

```solidity
function recordAssessment(address tokenAddress, uint256 probability, bytes32 assessmentId) external onlyAgent;
function getAssessment(address tokenAddress) external view returns (RiskAssessment memory);
function assessmentExists(address tokenAddress) external view returns (bool);
```

### Events

```solidity
event AssessmentRecorded(address indexed token, uint256 probability, bytes32 indexed assessmentId);
```

### Custom Errors

```solidity
error AssessmentAlreadyExists();
error InvalidProbability();
error NotAuthorizedAgent();
```

---

## 6. AttestationAdapter

### Functions

```solidity
function attestResult(bytes32 poolId, bool predictedOutcome, bool actualOutcome) external returns (bytes32 uid);
function getAttestation(bytes32 poolId) external view returns (Attestation memory);
```

### Events

```solidity
event Attested(bytes32 indexed poolId, bytes32 indexed easUid, bool predicted, bool actual);
```

### Custom Errors

```solidity
error AttestationAlreadyExists();
error EASContractError();
error PoolNotFound();
```

---

## NatSpec Conventions

```solidity
/// @title PredictionPool
/// @notice Manages binary prediction positions (YES/NO) for a single token
/// @dev Only OracleAdapter can trigger settlement
/// @custom:security ReentrancyGuard, Pausable

/// @notice Buys a position in the prediction pool
/// @param side YES (0) or NO (1)
/// @param amount Amount of tokens (wei)
/// @dev Reverts if pool is expired or inactive
/// @custom:emits PositionPurchased

/// @return payout Amount the user can claim (wei)
```

Template:
1. `@title` — Nama contract
2. `@notice` — Fungsi / kontrak secara singkat
3. `@dev` — Detail implementasi / caveat
4. `@param` — Setiap parameter
5. `@return` — Setiap return value (jika ada)
6. `@custom:security` — Security considerations
7. `@custom:emits` — Event yang dihasilkan
