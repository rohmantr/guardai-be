# Treasury Contract Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement Treasury vault contract — deposit, payout, fee management, pool registration.

**Architecture:** Treasury is a standalone vault with per-pool balance accounting. Functions derive `poolId` from `msg.sender` via a pool→id binding set at registration time. Uses `Ownable2Step` + `ReentrancyGuard`. No changes to existing `PredictionPool`.

**Tech Stack:** Solidity ^0.8.28, OpenZeppelin (Ownable2Step, ReentrancyGuard), Forge (test, build)

## Global Constraints

- Solidity ^0.8.28
- OpenZeppelin imports via `@openzeppelin/` remapping
- Forge build + test must pass
- No `tx.origin`, no `delegatecall`, no `selfdestruct`
- CEI pattern on all fund-moving functions
- Use `call{value}("")` for ETH transfers

---

### Task 1: ITreasury Interface

**Files:**
- Create: `contracts/src/interfaces/ITreasury.sol`

**Interfaces:**
- Produces: Interface consumed by Treasury.sol and tests

- [ ] **Step 1: Write ITreasury interface**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title ITreasury
/// @notice Interface for the Treasury vault contract
interface ITreasury {
    function registerPool(address pool, bytes32 poolId) external;
    function deposit() external payable;
    function payout(address winner, uint256 amount) external;
    function withdrawFees(address to, uint256 amount) external;
    function setFeeBps(uint256 newFeeBps) external;
    function getBalance(bytes32 poolId) external view returns (uint256);

    event PoolRegistered(address indexed pool, bytes32 indexed poolId);
    event Deposited(bytes32 indexed poolId, address indexed pool, uint256 amount);
    event PayoutSent(bytes32 indexed poolId, address indexed winner, uint256 amount);
    event FeesWithdrawn(address indexed to, uint256 amount);
    event FeeUpdated(uint256 newFeeBps);

    error InsufficientBalance();
    error TransferFailed();
    error UnauthorizedPool();
    error FeeTooHigh();
    error ZeroAddress();
    error PoolAlreadyRegistered();
    error PoolNotRegistered();
}
```

- [ ] **Step 2: Verify build**

Run: `forge build`
Expected: No errors (interface-only, no dependencies)

- [ ] **Step 3: Commit**

```bash
git add contracts/src/interfaces/ITreasury.sol
git commit -m "feat: add ITreasury interface"
```

---

### Task 2: Treasury Contract Implementation

**Files:**
- Create: `contracts/src/core/Treasury.sol`

**Interfaces:**
- Consumes: `ITreasury` from Task 1
- Produces: Treasury contract consumed by tests in Task 3

- [ ] **Step 1: Write Treasury contract**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable2Step} from "@openzeppelin/access/Ownable2Step.sol";
import {ReentrancyGuard} from "@openzeppelin/utils/ReentrancyGuard.sol";
import {ITreasury} from "../interfaces/ITreasury.sol";

/// @title Treasury
/// @notice Vault contract managing protocol funds per prediction pool
/// @dev Pool identity derived from msg.sender via registration binding. CEI pattern.
/// @custom:security Ownable2Step, ReentrancyGuard, CEI, zero-address checks
contract Treasury is ITreasury, Ownable2Step, ReentrancyGuard {
    // ──────────────────────────────────────────────
    //  State
    // ──────────────────────────────────────────────

    mapping(bytes32 => uint256) private _poolBalances;
    mapping(address => bool) public registeredPools;
    mapping(address => bytes32) public poolIdOf;
    uint256 public feeBps;
    uint256 private _accumulatedFees;

    uint256 public constant MAX_FEE_BPS = 1000;

    // ──────────────────────────────────────────────
    //  Modifiers
    // ──────────────────────────────────────────────

    modifier onlyRegisteredPool() {
        if (!registeredPools[msg.sender]) revert UnauthorizedPool();
        _;
    }

    // ──────────────────────────────────────────────
    //  Constructor
    // ──────────────────────────────────────────────

    /// @notice Deploys Treasury with zero fee initially
    /// @dev Owner sets feeBps after deployment
    constructor() Ownable(msg.sender) {}

    // ──────────────────────────────────────────────
    //  Owner
    // ──────────────────────────────────────────────

    /// @notice Registers a prediction pool address with its poolId
    /// @param pool Address of the PredictionPool contract
    /// @param _poolId Unique pool identifier
    /// @custom:emits PoolRegistered
    function registerPool(address pool, bytes32 _poolId) external onlyOwner {
        if (pool == address(0)) revert ZeroAddress();
        if (registeredPools[pool]) revert PoolAlreadyRegistered();

        registeredPools[pool] = true;
        poolIdOf[pool] = _poolId;

        emit PoolRegistered(pool, _poolId);
    }

    /// @notice Sets the fee in basis points (capped at 10%)
    /// @param newFeeBps New fee in basis points (e.g., 250 = 2.5%)
    /// @custom:emits FeeUpdated
    function setFeeBps(uint256 newFeeBps) external onlyOwner {
        if (newFeeBps > MAX_FEE_BPS) revert FeeTooHigh();
        feeBps = newFeeBps;
        emit FeeUpdated(newFeeBps);
    }

    // ──────────────────────────────────────────────
    //  Core
    // ──────────────────────────────────────────────

    /// @notice Deposits ETH into a pool's balance (caller must be registered pool)
    /// @dev poolId is derived from msg.sender via poolIdOf mapping
    /// @custom:emits Deposited
    function deposit() external payable onlyRegisteredPool {
        bytes32 _poolId = poolIdOf[msg.sender];

        uint256 fee = (msg.value * feeBps) / 10000;
        _accumulatedFees += fee;
        _poolBalances[_poolId] += msg.value - fee;

        emit Deposited(_poolId, msg.sender, msg.value - fee);
    }

    /// @notice Sends payout to a winner (caller must be registered pool)
    /// @param winner Address of the winner
    /// @param amount Amount of ETH to send
    /// @custom:security CEI: state update before external call, ReentrancyGuard
    /// @custom:emits PayoutSent
    function payout(address winner, uint256 amount)
        external
        nonReentrant
        onlyRegisteredPool
    {
        if (winner == address(0)) revert ZeroAddress();

        bytes32 _poolId = poolIdOf[msg.sender];

        if (_poolBalances[_poolId] < amount) revert InsufficientBalance();

        // CEI: state update before external call
        _poolBalances[_poolId] -= amount;

        (bool sent,) = payable(winner).call{value: amount}("");
        if (!sent) revert TransferFailed();

        emit PayoutSent(_poolId, winner, amount);
    }

    /// @notice Withdraws accumulated fees to a recipient
    /// @param to Recipient address
    /// @param amount Amount of ETH to withdraw
    /// @custom:security CEI: state update before external call, ReentrancyGuard
    /// @custom:emits FeesWithdrawn
    function withdrawFees(address to, uint256 amount)
        external
        nonReentrant
        onlyOwner
    {
        if (to == address(0)) revert ZeroAddress();

        if (_accumulatedFees < amount) revert InsufficientBalance();

        // CEI: state update before external call
        _accumulatedFees -= amount;

        (bool sent,) = payable(to).call{value: amount}("");
        if (!sent) revert TransferFailed();

        emit FeesWithdrawn(to, amount);
    }

    // ──────────────────────────────────────────────
    //  Getters
    // ──────────────────────────────────────────────

    /// @notice Returns the balance for a given pool
    function getBalance(bytes32 _poolId) external view returns (uint256) {
        return _poolBalances[_poolId];
    }
}
```

- [ ] **Step 2: Verify build**

Run: `forge build`
Expected: Compilation succeeds with no warnings

- [ ] **Step 3: Commit**

```bash
git add contracts/src/core/Treasury.sol
git commit -m "feat: implement Treasury contract"
```

---

### Task 3: Treasury Unit Tests

**Files:**
- Create: `contracts/test/Treasury.t.sol`

**Interfaces:**
- Consumes: `ITreasury`, `Treasury` from Tasks 1-2

- [ ] **Step 1: Write test contract with helpers**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console2} from "forge-std/Test.sol";
import {Treasury} from "../src/core/Treasury.sol";

contract TreasuryTest is Test {
    Treasury public treasury;
    address public owner = makeAddr("owner");
    address public pool = makeAddr("pool");
    address public winner = makeAddr("winner");
    address public stranger = makeAddr("stranger");
    bytes32 public poolId = keccak256("pool-1");

    event PoolRegistered(address indexed pool, bytes32 indexed poolId);
    event Deposited(bytes32 indexed poolId, address indexed pool, uint256 amount);
    event PayoutSent(bytes32 indexed poolId, address indexed winner, uint256 amount);
    event FeesWithdrawn(address indexed to, uint256 amount);
    event FeeUpdated(uint256 newFeeBps);

    function setUp() public {
        vm.prank(owner);
        treasury = new Treasury();
    }
```

- [ ] **Step 2: Write registration tests**

```solidity
    // ────────────────────────────────────────────
    //  Registration
    // ────────────────────────────────────────────

    function test_RegisterPool() public {
        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit PoolRegistered(pool, poolId);
        treasury.registerPool(pool, poolId);

        assertTrue(treasury.registeredPools(pool));
        assertEq(treasury.poolIdOf(pool), poolId);
    }

    function test_RevertWhen_RegisterPool_NotOwner() public {
        vm.prank(stranger);
        vm.expectRevert();
        treasury.registerPool(pool, poolId);
    }

    function test_RevertWhen_RegisterPool_ZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(Treasury.ZeroAddress.selector);
        treasury.registerPool(address(0), poolId);
    }

    function test_RevertWhen_RegisterPool_Duplicate() public {
        vm.prank(owner);
        treasury.registerPool(pool, poolId);

        vm.prank(owner);
        vm.expectRevert(Treasury.PoolAlreadyRegistered.selector);
        treasury.registerPool(pool, poolId);
    }
```

- [ ] **Step 3: Write deposit tests**

Note: Deposit must be called by registered pool. Use `vm.prank(pool)` and send ETH via `{value: X}`.

```solidity
    // ────────────────────────────────────────────
    //  Deposit
    // ────────────────────────────────────────────

    function test_Deposit() public {
        vm.prank(owner);
        treasury.registerPool(pool, poolId);

        vm.deal(pool, 10 ether);
        vm.prank(pool);
        vm.expectEmit(true, true, false, true);
        emit Deposited(poolId, pool, 10 ether);
        treasury.deposit{value: 10 ether}();

        assertEq(treasury.getBalance(poolId), 10 ether);
    }

    function test_Deposit_WithFee() public {
        vm.prank(owner);
        treasury.registerPool(pool, poolId);
        vm.prank(owner);
        treasury.setFeeBps(500); // 5%

        vm.deal(pool, 10 ether);
        vm.prank(pool);
        treasury.deposit{value: 10 ether}();

        // 5% fee → 0.5 ETH fee, 9.5 ETH pool balance
        assertEq(treasury.getBalance(poolId), 9.5 ether);
    }

    function test_RevertWhen_Deposit_UnregisteredPool() public {
        vm.deal(stranger, 1 ether);
        vm.prank(stranger);
        vm.expectRevert(Treasury.UnauthorizedPool.selector);
        treasury.deposit{value: 1 ether}();
    }

    function test_FeeAccumulates() public {
        vm.prank(owner);
        treasury.registerPool(pool, poolId);
        vm.prank(owner);
        treasury.setFeeBps(250); // 2.5%

        vm.deal(pool, 100 ether);
        vm.prank(pool);
        treasury.deposit{value: 100 ether}();

        // fee = 2.5 ETH, pool balance = 97.5 ETH
        assertEq(treasury.getBalance(poolId), 97.5 ether);
    }
```

- [ ] **Step 4: Write payout tests**

```solidity
    // ────────────────────────────────────────────
    //  Payout
    // ────────────────────────────────────────────

    function test_Payout() public {
        vm.prank(owner);
        treasury.registerPool(pool, poolId);

        vm.deal(pool, 10 ether);
        vm.prank(pool);
        treasury.deposit{value: 10 ether}();

        uint256 balanceBefore = address(winner).balance;

        vm.prank(pool);
        vm.expectEmit(true, true, false, true);
        emit PayoutSent(poolId, winner, 5 ether);
        treasury.payout(winner, 5 ether);

        assertEq(address(winner).balance, balanceBefore + 5 ether);
        assertEq(treasury.getBalance(poolId), 5 ether);
    }

    function test_RevertWhen_Payout_UnregisteredPool() public {
        vm.prank(stranger);
        vm.expectRevert(Treasury.UnauthorizedPool.selector);
        treasury.payout(winner, 1 ether);
    }

    function test_RevertWhen_Payout_ZeroAddress() public {
        vm.prank(owner);
        treasury.registerPool(pool, poolId);

        vm.prank(pool);
        vm.expectRevert(Treasury.ZeroAddress.selector);
        treasury.payout(address(0), 1 ether);
    }

    function test_RevertWhen_Payout_InsufficientBalance() public {
        vm.prank(owner);
        treasury.registerPool(pool, poolId);

        vm.deal(pool, 1 ether);
        vm.prank(pool);
        treasury.deposit{value: 1 ether}();

        vm.prank(pool);
        vm.expectRevert(Treasury.InsufficientBalance.selector);
        treasury.payout(winner, 2 ether);
    }
```

- [ ] **Step 5: Write withdraw fees tests**

```solidity
    // ────────────────────────────────────────────
    //  Withdraw Fees
    // ────────────────────────────────────────────

    function test_WithdrawFees() public {
        vm.prank(owner);
        treasury.registerPool(pool, poolId);
        vm.prank(owner);
        treasury.setFeeBps(1000); // 10%

        vm.deal(pool, 100 ether);
        vm.prank(pool);
        treasury.deposit{value: 100 ether}();

        uint256 balanceBefore = address(owner).balance;

        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit FeesWithdrawn(owner, 10 ether);
        treasury.withdrawFees(owner, 10 ether);

        assertEq(address(owner).balance, balanceBefore + 10 ether);
    }

    function test_RevertWhen_WithdrawFees_NotOwner() public {
        vm.prank(stranger);
        vm.expectRevert();
        treasury.withdrawFees(stranger, 1 ether);
    }

    function test_RevertWhen_WithdrawFees_ZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(Treasury.ZeroAddress.selector);
        treasury.withdrawFees(address(0), 1 ether);
    }

    function test_RevertWhen_WithdrawFees_InsufficientBalance() public {
        vm.prank(owner);
        vm.expectRevert(Treasury.InsufficientBalance.selector);
        treasury.withdrawFees(owner, 1 ether);
    }
```

- [ ] **Step 6: Write set fee tests**

```solidity
    // ────────────────────────────────────────────
    //  Set Fee
    // ────────────────────────────────────────────

    function test_SetFeeBps() public {
        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit FeeUpdated(500);
        treasury.setFeeBps(500);

        assertEq(treasury.feeBps(), 500);
    }

    function test_RevertWhen_SetFeeBps_ExceedsMax() public {
        vm.prank(owner);
        vm.expectRevert(Treasury.FeeTooHigh.selector);
        treasury.setFeeBps(1001);
    }

    function test_RevertWhen_SetFeeBps_NotOwner() public {
        vm.prank(stranger);
        vm.expectRevert();
        treasury.setFeeBps(500);
    }
```

- [ ] **Step 7: Write invariant test**

```solidity
    // ────────────────────────────────────────────
    //  Invariant
    // ────────────────────────────────────────────

    function test_Invariant_BalanceMatchesPoolBalancesPlusFees() public {
        vm.prank(owner);
        treasury.registerPool(pool, poolId);
        vm.prank(owner);
        treasury.setFeeBps(200); // 2%

        vm.deal(pool, 50 ether);
        vm.prank(pool);
        treasury.deposit{value: 50 ether}(); // fee=1, pool=49

        assertEq(address(treasury).balance, 50 ether);

        vm.prank(owner);
        treasury.withdrawFees(owner, 1 ether);

        assertEq(address(treasury).balance, 49 ether);
        assertEq(treasury.getBalance(poolId), 49 ether);
    }

    function test_RevertWhen_StrayEth() public {
        // send ETH without going through deposit() should revert (no receive/fallback)
        vm.deal(stranger, 1 ether);
        vm.expectRevert();
        payable(address(treasury)).call{value: 1 ether}("");
    }
```

- [ ] **Step 8: Close test contract and run**

Add closing brace and run:

```bash
forge test --match-path contracts/test/Treasury.t.sol -vvv
```

Expected: All tests pass

- [ ] **Step 9: Commit**

```bash
git add contracts/test/Treasury.t.sol
git commit -m "test: add Treasury unit tests"
```

---

### Task 4: Final verification

- [ ] **Step 1: Full forge build**

```bash
forge build
```

Expected: No warnings, no errors

- [ ] **Step 2: Full forge test**

```bash
forge test -vvv
```

Expected: All tests pass (PredictionPool + Treasury)

- [ ] **Step 3: Format**

```bash
forge fmt
```

Expected: No formatting changes or applied cleanly
