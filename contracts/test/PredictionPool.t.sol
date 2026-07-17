// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console2} from "forge-std/Test.sol";
import {PredictionPool} from "../src/core/PredictionPool.sol";
import {IPredictionPool} from "../src/interfaces/IPredictionPool.sol";

contract PredictionPoolTest is Test {
    PredictionPool pool;
    address oracle = makeAddr("oracle");
    address trader1 = makeAddr("trader1");
    address trader2 = makeAddr("trader2");
    address owner = makeAddr("owner");

    bytes32 constant POOL_ID = keccak256("pool-001");
    address constant TOKEN_ADDRESS = address(0x123);
    uint256 constant DEADLINE = 1_000_000;

    event PoolCreated(bytes32 indexed poolId, address indexed token, uint256 deadline);
    event PositionPurchased(bytes32 indexed poolId, address indexed user, IPredictionPool.Side side, uint256 amount);
    event PoolResolved(bytes32 indexed poolId, IPredictionPool.Side winningSide, uint256 totalYes, uint256 totalNo);
    event ClaimExecuted(bytes32 indexed poolId, address indexed user, uint256 payout);
    event PoolExpired(bytes32 indexed poolId);
    event OracleAdapterUpdated(address indexed oldAdapter, address indexed newAdapter);

    function setUp() public {
        vm.prank(owner);
        pool = new PredictionPool(POOL_ID, TOKEN_ADDRESS, oracle, DEADLINE);
    }

    // ──────────────────────────────────────────────
    //  Constructor
    // ──────────────────────────────────────────────

    function test_Constructor_SetsState() public view {
        assertEq(pool.poolId(), POOL_ID);
        assertEq(pool.tokenAddress(), TOKEN_ADDRESS);
        assertEq(pool.oracleAdapter(), oracle);
        assertEq(pool.deadline(), DEADLINE);
        assertTrue(pool.isActive());
        assertEq(uint256(pool.status()), uint256(IPredictionPool.PoolStatus.Active));
    }

    function test_Constructor_EmitsEvent() public {
        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit PoolCreated(POOL_ID, TOKEN_ADDRESS, DEADLINE);
        new PredictionPool(POOL_ID, TOKEN_ADDRESS, oracle, DEADLINE);
    }

    function test_Constructor_SetsOwner() public view {
        assertEq(pool.owner(), owner);
    }

    // ──────────────────────────────────────────────
    //  buyPosition
    // ──────────────────────────────────────────────

    function test_BuyPosition_Yes() public {
        vm.deal(trader1, 10 ether);
        vm.prank(trader1);

        vm.expectEmit(true, true, true, true);
        emit PositionPurchased(POOL_ID, trader1, IPredictionPool.Side.YES, 5 ether);

        pool.buyPosition{value: 5 ether}(IPredictionPool.Side.YES, 5 ether);
        assertEq(pool.yesPool(), 5 ether);
        assertEq(pool.noPool(), 0);
    }

    function test_BuyPosition_No() public {
        vm.deal(trader1, 10 ether);
        vm.prank(trader1);
        pool.buyPosition{value: 3 ether}(IPredictionPool.Side.NO, 3 ether);
        assertEq(pool.yesPool(), 0);
        assertEq(pool.noPool(), 3 ether);
    }

    function test_BuyPosition_MultipleAggregated() public {
        vm.deal(trader1, 10 ether);

        vm.startPrank(trader1);
        pool.buyPosition{value: 2 ether}(IPredictionPool.Side.YES, 2 ether);
        pool.buyPosition{value: 3 ether}(IPredictionPool.Side.YES, 3 ether);
        vm.stopPrank();

        assertEq(pool.yesPool(), 5 ether);

        IPredictionPool.UserPosition memory pos = pool.getPosition(trader1);
        assertEq(pos.yesAmount, 5 ether);
        assertEq(pos.noAmount, 0);
    }

    function test_BuyPosition_BothSides() public {
        vm.deal(trader1, 10 ether);

        vm.startPrank(trader1);
        pool.buyPosition{value: 4 ether}(IPredictionPool.Side.YES, 4 ether);
        pool.buyPosition{value: 3 ether}(IPredictionPool.Side.NO, 3 ether);
        vm.stopPrank();

        assertEq(pool.yesPool(), 4 ether);
        assertEq(pool.noPool(), 3 ether);

        IPredictionPool.UserPosition memory pos = pool.getPosition(trader1);
        assertEq(pos.yesAmount, 4 ether);
        assertEq(pos.noAmount, 3 ether);
    }

    function test_BuyPosition_MultipleTraders() public {
        vm.deal(trader1, 10 ether);
        vm.deal(trader2, 10 ether);

        vm.prank(trader1);
        pool.buyPosition{value: 5 ether}(IPredictionPool.Side.YES, 5 ether);

        vm.prank(trader2);
        pool.buyPosition{value: 7 ether}(IPredictionPool.Side.NO, 7 ether);

        assertEq(pool.yesPool(), 5 ether);
        assertEq(pool.noPool(), 7 ether);
    }

    function test_BuyPosition_Reverts_ZeroAmount() public {
        vm.deal(trader1, 1 ether);
        vm.prank(trader1);
        vm.expectRevert(PredictionPool.PositionTooSmall.selector);
        pool.buyPosition{value: 0}(IPredictionPool.Side.YES, 0);
    }

    function test_BuyPosition_Reverts_InsufficientPayment() public {
        vm.deal(trader1, 1 ether);
        vm.prank(trader1);
        vm.expectRevert(PredictionPool.InsufficientPayment.selector);
        pool.buyPosition{value: 1 ether}(IPredictionPool.Side.YES, 2 ether);
    }

    function test_BuyPosition_Reverts_AfterExpire() public {
        vm.warp(DEADLINE + 1);
        vm.deal(trader1, 1 ether);
        vm.prank(trader1);
        vm.expectRevert(PredictionPool.PoolAlreadyExpired.selector);
        pool.buyPosition{value: 1 ether}(IPredictionPool.Side.YES, 1 ether);
    }

    function test_BuyPosition_Reverts_WhenPaused() public {
        vm.prank(owner);
        pool.pause();

        vm.deal(trader1, 1 ether);
        vm.prank(trader1);
        vm.expectRevert();
        pool.buyPosition{value: 1 ether}(IPredictionPool.Side.YES, 1 ether);
    }

    function test_BuyPosition_Reverts_AfterSettle() public {
        vm.deal(trader1, 1 ether);
        vm.prank(trader1);
        pool.buyPosition{value: 1 ether}(IPredictionPool.Side.YES, 1 ether);

        vm.prank(oracle);
        pool.settle(true);

        vm.deal(trader2, 1 ether);
        vm.prank(trader2);
        vm.expectRevert(PredictionPool.PoolNotActive.selector);
        pool.buyPosition{value: 1 ether}(IPredictionPool.Side.NO, 1 ether);
    }

    function test_BuyPosition_OverpayAllowed() public {
        vm.deal(trader1, 10 ether);
        vm.prank(trader1);
        pool.buyPosition{value: 10 ether}(IPredictionPool.Side.YES, 5 ether);
        assertEq(pool.yesPool(), 5 ether);
        // Extra ETH stays in contract — no revert
    }

    // ──────────────────────────────────────────────
    //  settle
    // ──────────────────────────────────────────────

    function test_Settle_YesWins() public {
        vm.prank(oracle);
        vm.expectEmit(true, true, true, true);
        emit PoolResolved(POOL_ID, IPredictionPool.Side.YES, 0, 0);
        pool.settle(true);

        assertFalse(pool.isActive());
        assertTrue(pool.isResolved());

        IPredictionPool.PoolInfo memory info = pool.getPoolInfo();
        assertEq(uint256(info.winningSide), uint256(IPredictionPool.Side.YES));
    }

    function test_Settle_NoWins() public {
        vm.prank(oracle);
        pool.settle(false);

        IPredictionPool.PoolInfo memory info = pool.getPoolInfo();
        assertEq(uint256(info.winningSide), uint256(IPredictionPool.Side.NO));
    }

    function test_Settle_Reverts_NotOracle() public {
        vm.prank(trader1);
        vm.expectRevert(PredictionPool.NotOracleAdapter.selector);
        pool.settle(true);
    }

    function test_Settle_Reverts_DoubleSettle() public {
        vm.prank(oracle);
        pool.settle(true);

        vm.prank(oracle);
        vm.expectRevert(PredictionPool.PoolNotActive.selector);
        pool.settle(true);
    }

    function test_Settle_Reverts_AfterExpired() public {
        vm.warp(DEADLINE + 1);
        vm.prank(oracle);
        vm.expectRevert(PredictionPool.PoolAlreadyExpired.selector);
        pool.settle(true);
    }

    function test_Settle_Reverts_BeforeDeadline() public {
        // Should succeed before deadline
        vm.warp(DEADLINE - 100);
        vm.prank(oracle);
        pool.settle(true);
        assertTrue(pool.isResolved());
    }

    // ──────────────────────────────────────────────
    //  claim
    // ──────────────────────────────────────────────

    function test_Claim_YesWins_Proportional() public {
        vm.deal(trader1, 10 ether);
        vm.deal(trader2, 10 ether);

        vm.prank(trader1);
        pool.buyPosition{value: 5 ether}(IPredictionPool.Side.YES, 5 ether);

        vm.prank(trader2);
        pool.buyPosition{value: 5 ether}(IPredictionPool.Side.NO, 5 ether);

        vm.prank(oracle);
        pool.settle(true); // YES wins

        uint256 balanceBefore = address(trader1).balance;
        vm.prank(trader1);
        uint256 payout = pool.claim(trader1);
        uint256 balanceAfter = address(trader1).balance;

        assertEq(payout, 10 ether); // 5 YES / 5 totalYES * 10 totalPool = 10
        assertEq(balanceAfter - balanceBefore, 10 ether);
    }

    function test_Claim_NoWins_Proportional() public {
        vm.deal(trader1, 10 ether);
        vm.deal(trader2, 10 ether);

        vm.prank(trader1);
        pool.buyPosition{value: 2 ether}(IPredictionPool.Side.YES, 2 ether);

        vm.prank(trader2);
        pool.buyPosition{value: 8 ether}(IPredictionPool.Side.NO, 8 ether);

        vm.prank(oracle);
        pool.settle(false); // NO wins

        uint256 balanceBefore = address(trader2).balance;
        vm.prank(trader2);
        uint256 payout = pool.claim(trader2);
        uint256 balanceAfter = address(trader2).balance;

        // trader2: 8 NO / 8 totalNO * 10 totalPool = 10
        assertEq(payout, 10 ether);
        assertEq(balanceAfter - balanceBefore, 10 ether);
    }

    function test_Claim_MultipleYesPositions() public {
        vm.deal(trader1, 10 ether);

        vm.startPrank(trader1);
        pool.buyPosition{value: 2 ether}(IPredictionPool.Side.YES, 2 ether);
        pool.buyPosition{value: 3 ether}(IPredictionPool.Side.YES, 3 ether);
        vm.stopPrank();

        vm.deal(trader2, 10 ether);
        vm.prank(trader2);
        pool.buyPosition{value: 5 ether}(IPredictionPool.Side.NO, 5 ether);

        vm.prank(oracle);
        pool.settle(true); // YES wins

        vm.prank(trader1);
        uint256 payout = pool.claim(trader1);
        assertEq(payout, 10 ether); // 5 YES / 5 totalYES * 10 totalPool = 10
    }

    function test_Claim_Reverts_DoubleClaim() public {
        vm.deal(trader1, 10 ether);
        vm.prank(trader1);
        pool.buyPosition{value: 1 ether}(IPredictionPool.Side.YES, 1 ether);

        vm.prank(oracle);
        pool.settle(true);

        vm.prank(trader1);
        pool.claim(trader1);

        vm.prank(trader1);
        vm.expectRevert(PredictionPool.AlreadyClaimed.selector);
        pool.claim(trader1);
    }

    function test_Claim_Reverts_NotResolved() public {
        vm.deal(trader1, 1 ether);
        vm.prank(trader1);
        pool.buyPosition{value: 1 ether}(IPredictionPool.Side.YES, 1 ether);

        vm.prank(trader1);
        vm.expectRevert(PredictionPool.PoolNotResolved.selector);
        pool.claim(trader1);
    }

    function test_Claim_Reverts_NothingToClaim_LoserSide() public {
        vm.deal(trader1, 10 ether);
        vm.deal(trader2, 10 ether);

        vm.prank(trader1);
        pool.buyPosition{value: 5 ether}(IPredictionPool.Side.YES, 5 ether);

        vm.prank(trader2);
        pool.buyPosition{value: 5 ether}(IPredictionPool.Side.NO, 5 ether);

        vm.prank(oracle);
        pool.settle(true); // YES wins

        // trader2 (NO holder) tries to claim
        vm.prank(trader2);
        vm.expectRevert(PredictionPool.NothingToClaim.selector);
        pool.claim(trader2);
    }

    function test_Claim_Reverts_NoPositions() public {
        vm.prank(oracle);
        pool.settle(true);

        vm.prank(trader1);
        vm.expectRevert(PredictionPool.NothingToClaim.selector);
        pool.claim(trader1);
    }

    // ──────────────────────────────────────────────
    //  expire
    // ──────────────────────────────────────────────

    function test_Expire_AfterDeadline() public {
        vm.warp(DEADLINE + 1);

        vm.expectEmit(true, false, false, false);
        emit PoolExpired(POOL_ID);

        pool.expire();
        assertFalse(pool.isActive());
    }

    function test_Expire_Reverts_BeforeDeadline() public {
        vm.warp(DEADLINE - 1);
        vm.expectRevert(PredictionPool.DeadlineNotReached.selector);
        pool.expire();
    }

    function test_Expire_Reverts_AfterSettle() public {
        vm.prank(oracle);
        pool.settle(true);

        vm.warp(DEADLINE + 1);
        vm.expectRevert(PredictionPool.PoolNotActive.selector);
        pool.expire();
    }

    function test_Expire_AnyoneCanCall() public {
        vm.warp(DEADLINE + 1);
        vm.prank(trader1);
        pool.expire();
        assertFalse(pool.isActive());
    }

    // ──────────────────────────────────────────────
    //  Pause / Unpause
    // ──────────────────────────────────────────────

    function test_Pause() public {
        vm.prank(owner);
        pool.pause();

        vm.deal(trader1, 1 ether);
        vm.prank(trader1);
        vm.expectRevert();
        pool.buyPosition{value: 1 ether}(IPredictionPool.Side.YES, 1 ether);
    }

    function test_Unpause() public {
        vm.prank(owner);
        pool.pause();

        vm.prank(owner);
        pool.unpause();

        vm.deal(trader1, 1 ether);
        vm.prank(trader1);
        pool.buyPosition{value: 1 ether}(IPredictionPool.Side.YES, 1 ether);
        assertEq(pool.yesPool(), 1 ether);
    }

    function test_Pause_Reverts_NotOwner() public {
        vm.prank(trader1);
        vm.expectRevert();
        pool.pause();
    }

    // ──────────────────────────────────────────────
    //  setOracleAdapter
    // ──────────────────────────────────────────────

    function test_SetOracleAdapter() public {
        address newOracle = makeAddr("newOracle");
        vm.expectEmit(true, true, false, false);
        emit OracleAdapterUpdated(oracle, newOracle);

        vm.prank(owner);
        pool.setOracleAdapter(newOracle);
        assertEq(pool.oracleAdapter(), newOracle);
    }

    function test_SetOracleAdapter_Reverts_NotOwner() public {
        vm.prank(trader1);
        vm.expectRevert();
        pool.setOracleAdapter(makeAddr("newOracle"));
    }

    function test_NewOracleCanSettle() public {
        address newOracle = makeAddr("newOracle");

        vm.prank(owner);
        pool.setOracleAdapter(newOracle);

        vm.prank(newOracle);
        pool.settle(true);
        assertTrue(pool.isResolved());
    }

    // ──────────────────────────────────────────────
    //  Getters
    // ──────────────────────────────────────────────

    function test_GetPoolInfo() public view {
        IPredictionPool.PoolInfo memory info = pool.getPoolInfo();
        assertEq(info.poolId, POOL_ID);
        assertEq(info.tokenAddress, TOKEN_ADDRESS);
        assertEq(info.yesPool, 0);
        assertEq(info.noPool, 0);
        assertEq(uint256(info.status), uint256(IPredictionPool.PoolStatus.Active));
        assertEq(info.deadline, DEADLINE);
    }

    function test_GetPoolInfo_AfterSettle() public {
        vm.deal(trader1, 5 ether);
        vm.prank(trader1);
        pool.buyPosition{value: 5 ether}(IPredictionPool.Side.YES, 5 ether);

        vm.prank(oracle);
        pool.settle(true);

        IPredictionPool.PoolInfo memory info = pool.getPoolInfo();
        assertEq(info.yesPool, 5 ether);
        assertEq(uint256(info.winningSide), uint256(IPredictionPool.Side.YES));
    }

    function test_IsActive() public {
        assertTrue(pool.isActive());
        vm.prank(oracle);
        pool.settle(true);
        assertFalse(pool.isActive());
    }

    function test_IsResolved() public {
        assertFalse(pool.isResolved());
        vm.prank(oracle);
        pool.settle(true);
        assertTrue(pool.isResolved());
    }

    // ──────────────────────────────────────────────
    //  Fuzz
    // ──────────────────────────────────────────────

    function testFuzz_BuyAndSettle(uint256 yesAmount, uint256 noAmount) public {
        vm.assume(yesAmount > 0.001 ether && yesAmount < 100 ether);
        vm.assume(noAmount > 0.001 ether && noAmount < 100 ether);

        address alice = makeAddr("alice");
        address bob = makeAddr("bob");

        vm.deal(alice, yesAmount);
        vm.deal(bob, noAmount);

        vm.prank(alice);
        pool.buyPosition{value: yesAmount}(IPredictionPool.Side.YES, yesAmount);

        vm.prank(bob);
        pool.buyPosition{value: noAmount}(IPredictionPool.Side.NO, noAmount);

        vm.prank(oracle);
        pool.settle(true); // YES wins

        vm.prank(alice);
        uint256 payout = pool.claim(alice);

        uint256 totalPool = yesAmount + noAmount;
        assertEq(payout, (yesAmount * totalPool) / yesAmount);
    }

    // ──────────────────────────────────────────────
    //  Receive (reject direct ETH transfers)
    // ──────────────────────────────────────────────

    receive() external payable {
        revert("Direct transfers not allowed");
    }

    // Override receive to test that pool rejects direct transfers
    function test_DirectTransfer_Reverts() public {
        vm.deal(address(this), 1 ether);
        (bool ok,) = address(pool).call{value: 1 ether}("");
        assertFalse(ok);
    }
}
