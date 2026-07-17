// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console2} from "forge-std/Test.sol";
import {ITreasury} from "../src/interfaces/ITreasury.sol";
import {Treasury} from "../src/core/Treasury.sol";

// ──────────────────────────────────────────────
//  Helper contracts for security tests
// ──────────────────────────────────────────────

/// @dev Malicious contract that tries to re-enter Treasury.payout on ETH receive
contract ReentrancyAttacker {
    Treasury public treasury;
    address public reenterTarget;
    uint256 public attackAmount;

    constructor(Treasury _treasury, address _reenterTarget, uint256 _attackAmount) {
        treasury = _treasury;
        reenterTarget = _reenterTarget;
        attackAmount = _attackAmount;
    }

    receive() external payable {
        // Try to re-enter payout with a different target
        if (address(treasury).balance >= attackAmount) {
            treasury.payout(reenterTarget, attackAmount);
        }
    }

    /// @notice Start the attack: send ETH to ourselves, triggering receive() which re-enters
    function attack() external {
        treasury.payout(address(this), attackAmount);
    }
}

/// @dev Contract that reverts on ETH receive
contract RevertingReceiver {
    receive() external payable {
        revert("I reject ETH");
    }
}

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

    // ────────────────────────────────────────────
    //  Registration
    // ────────────────────────────────────────────

    function test_RegisterPool_success() public {
        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit PoolRegistered(pool, poolId);
        treasury.registerPool(pool, poolId);

        assertTrue(treasury.registeredPools(pool));
        assertEq(treasury.poolIdOf(pool), poolId);
    }

    function test_RegisterPool_revertNonOwner() public {
        vm.prank(stranger);
        vm.expectRevert();
        treasury.registerPool(pool, poolId);
    }

    function test_RegisterPool_revertZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(ITreasury.ZeroAddress.selector);
        treasury.registerPool(address(0), poolId);
    }

    function test_RegisterPool_revertDuplicate() public {
        vm.prank(owner);
        treasury.registerPool(pool, poolId);

        vm.prank(owner);
        vm.expectRevert(ITreasury.PoolAlreadyRegistered.selector);
        treasury.registerPool(pool, poolId);
    }

    // ────────────────────────────────────────────
    //  Deposit
    // ────────────────────────────────────────────

    function test_deposit_success() public {
        vm.prank(owner);
        treasury.registerPool(pool, poolId);

        vm.deal(pool, 10 ether);
        vm.prank(pool);
        vm.expectEmit(true, true, false, true);
        emit Deposited(poolId, pool, 10 ether);
        treasury.deposit{value: 10 ether}();

        assertEq(treasury.getBalance(poolId), 10 ether);
    }

    function test_deposit_feeZero() public {
        vm.prank(owner);
        treasury.registerPool(pool, poolId);
        // feeBps defaults to 0

        vm.deal(pool, 5 ether);
        vm.prank(pool);
        treasury.deposit{value: 5 ether}();

        assertEq(treasury.getBalance(poolId), 5 ether);
    }

    function test_deposit_feeAtMax() public {
        vm.prank(owner);
        treasury.registerPool(pool, poolId);
        vm.prank(owner);
        treasury.setFeeBps(1000); // 10% (max)

        vm.deal(pool, 100 ether);
        vm.prank(pool);
        treasury.deposit{value: 100 ether}();

        // 10% fee → 10 ETH fee, 90 ETH pool balance
        assertEq(treasury.getBalance(poolId), 90 ether);
    }

    function test_deposit_revertUnregisteredPool() public {
        vm.deal(stranger, 1 ether);
        vm.prank(stranger);
        vm.expectRevert(ITreasury.UnauthorizedPool.selector);
        treasury.deposit{value: 1 ether}();
    }

    function test_deposit_feeAccumulates() public {
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

    // ────────────────────────────────────────────
    //  Payout
    // ────────────────────────────────────────────

    function test_payout_success() public {
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

    function test_payout_revertUnregisteredPool() public {
        vm.prank(stranger);
        vm.expectRevert(ITreasury.UnauthorizedPool.selector);
        treasury.payout(winner, 1 ether);
    }

    function test_payout_revertZeroAddressWinner() public {
        vm.prank(owner);
        treasury.registerPool(pool, poolId);

        vm.prank(pool);
        vm.expectRevert(ITreasury.ZeroAddress.selector);
        treasury.payout(address(0), 1 ether);
    }

    function test_payout_revertInsufficientBalance() public {
        vm.prank(owner);
        treasury.registerPool(pool, poolId);

        vm.deal(pool, 1 ether);
        vm.prank(pool);
        treasury.deposit{value: 1 ether}();

        vm.prank(pool);
        vm.expectRevert(ITreasury.InsufficientBalance.selector);
        treasury.payout(winner, 2 ether);
    }

    function test_payout_amountEqualsBalanceExact() public {
        vm.prank(owner);
        treasury.registerPool(pool, poolId);

        vm.deal(pool, 8 ether);
        vm.prank(pool);
        treasury.deposit{value: 8 ether}();

        uint256 balanceBefore = address(winner).balance;

        vm.prank(pool);
        treasury.payout(winner, 8 ether);

        assertEq(address(winner).balance, balanceBefore + 8 ether);
        assertEq(treasury.getBalance(poolId), 0);
    }

    // ────────────────────────────────────────────
    //  Withdraw Fees
    // ────────────────────────────────────────────

    function test_withdrawFees_success() public {
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

    function test_withdrawFees_revertNonOwner() public {
        vm.prank(stranger);
        vm.expectRevert();
        treasury.withdrawFees(stranger, 1 ether);
    }

    function test_withdrawFees_revertZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(ITreasury.ZeroAddress.selector);
        treasury.withdrawFees(address(0), 1 ether);
    }

    function test_withdrawFees_revertInsufficientFees() public {
        vm.prank(owner);
        vm.expectRevert(ITreasury.InsufficientBalance.selector);
        treasury.withdrawFees(owner, 1 ether);
    }

    // ────────────────────────────────────────────
    //  Set Fee
    // ────────────────────────────────────────────

    function test_setFeeBps_success() public {
        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit FeeUpdated(500);
        treasury.setFeeBps(500);

        assertEq(treasury.feeBps(), 500);
    }

    function test_setFeeBps_revertExceedsMax() public {
        vm.prank(owner);
        vm.expectRevert(ITreasury.FeeTooHigh.selector);
        treasury.setFeeBps(1001);
    }

    function test_setFeeBps_revertNonOwner() public {
        vm.prank(stranger);
        vm.expectRevert();
        treasury.setFeeBps(500);
    }

    function test_setFeeBps_atMaxBoundary() public {
        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit FeeUpdated(1000);
        treasury.setFeeBps(1000);

        assertEq(treasury.feeBps(), 1000);
    }

    // ────────────────────────────────────────────
    //  getBalance
    // ────────────────────────────────────────────

    function test_getBalance_returnsCorrectAmount() public {
        vm.prank(owner);
        treasury.registerPool(pool, poolId);

        assertEq(treasury.getBalance(poolId), 0);

        vm.deal(pool, 3 ether);
        vm.prank(pool);
        treasury.deposit{value: 3 ether}();

        assertEq(treasury.getBalance(poolId), 3 ether);
    }

    // ────────────────────────────────────────────
    //  Fuzz tests
    // ────────────────────────────────────────────

    function testFuzz_deposit(uint256 amount, uint256 feeBps) public {
        feeBps = bound(feeBps, 0, 1000);
        amount = bound(amount, 0.001 ether, 1000 ether);

        vm.startPrank(owner);
        treasury.registerPool(pool, poolId);
        if (feeBps > 0) {
            treasury.setFeeBps(feeBps);
        }
        vm.stopPrank();

        uint256 expectedFee = (amount * feeBps) / 10000;
        uint256 expectedNet = amount - expectedFee;

        vm.deal(pool, amount);
        vm.prank(pool);
        treasury.deposit{value: amount}();

        assertEq(treasury.getBalance(poolId), expectedNet);

        assertEq(address(treasury).balance, amount);
    }

    function testFuzz_payout(uint256 depositAmount, uint256 payoutAmount) public {
        depositAmount = bound(depositAmount, 0.001 ether, 100 ether);
        payoutAmount = bound(payoutAmount, 0, depositAmount);

        vm.startPrank(owner);
        treasury.registerPool(pool, poolId);
        vm.stopPrank();

        vm.deal(pool, depositAmount);
        vm.prank(pool);
        treasury.deposit{value: depositAmount}();

        address fuzzWinner = makeAddr("fuzzWinner");
        uint256 balanceBefore = fuzzWinner.balance;

        vm.prank(pool);
        treasury.payout(fuzzWinner, payoutAmount);

        assertEq(fuzzWinner.balance, balanceBefore + payoutAmount);
        assertEq(treasury.getBalance(poolId), depositAmount - payoutAmount);
    }

    // ────────────────────────────────────────────
    //  Security: Reentrancy
    // ────────────────────────────────────────────

    function test_payout_reentrancyBlocked() public {
        ReentrancyAttacker attacker = new ReentrancyAttacker(treasury, winner, 1 ether);

        vm.prank(owner);
        treasury.registerPool(address(attacker), poolId);

        vm.deal(address(attacker), 10 ether);
        vm.prank(address(attacker));
        treasury.deposit{value: 10 ether}();

        uint256 treasuryBefore = address(treasury).balance;

        vm.prank(address(attacker));
        vm.expectRevert();
        attacker.attack();

        assertEq(address(treasury).balance, treasuryBefore);
    }

    // ────────────────────────────────────────────
    //  Security: Transfer failure handling
    // ────────────────────────────────────────────

    function test_payout_transferFailureHandledCleanly() public {
        RevertingReceiver receiver = new RevertingReceiver();

        vm.prank(owner);
        treasury.registerPool(pool, poolId);

        vm.deal(pool, 5 ether);
        vm.prank(pool);
        treasury.deposit{value: 5 ether}();

        uint256 balanceBefore = address(treasury).balance;

        vm.prank(pool);
        vm.expectRevert(ITreasury.TransferFailed.selector);
        treasury.payout(address(receiver), 5 ether);

        assertEq(address(treasury).balance, balanceBefore);
        assertEq(treasury.getBalance(poolId), 5 ether);
    }

    function test_withdrawFees_transferFailureHandledCleanly() public {
        RevertingReceiver receiver = new RevertingReceiver();

        vm.prank(owner);
        treasury.registerPool(pool, poolId);
        vm.prank(owner);
        treasury.setFeeBps(500); // 5%

        vm.deal(pool, 100 ether);
        vm.prank(pool);
        treasury.deposit{value: 100 ether}();

        uint256 balanceBefore = address(treasury).balance;

        vm.prank(owner);
        vm.expectRevert(ITreasury.TransferFailed.selector);
        treasury.withdrawFees(address(receiver), 5 ether);

        assertEq(address(treasury).balance, balanceBefore);
    }
}
