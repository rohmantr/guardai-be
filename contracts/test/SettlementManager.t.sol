// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {IPredictionPool} from "../src/interfaces/IPredictionPool.sol";
import {ISettlementManager} from "../src/interfaces/ISettlementManager.sol";
import {SettlementManager} from "../src/settlement/SettlementManager.sol";
import {PredictionPool} from "../src/core/PredictionPool.sol";

contract SettlementManagerTest is Test {
    SettlementManager public manager;
    PredictionPool public pool;
    address public owner = makeAddr("owner");
    address public oracle = makeAddr("oracle");
    address public stranger = makeAddr("stranger");
    address public tokenA = makeAddr("tokenA");
    address public user = makeAddr("user");
    bytes32 public poolId = keccak256("pool-1");
    uint256 public poolDeadline = block.timestamp + 7 days;
    uint256 public settlementDeadline = block.timestamp + 1 days;

    event PoolRegistered(bytes32 indexed poolId, address indexed pool);
    event SettlementScheduled(bytes32 indexed poolId, uint256 deadline);
    event SettlementExecuted(bytes32 indexed poolId, bool outcome);

    function setUp() public {
        vm.prank(owner);
        manager = new SettlementManager(oracle);

        vm.prank(owner);
        pool = new PredictionPool(poolId, tokenA, address(manager), poolDeadline);
    }

    // ──────────────────────────────────────────────
    //  registerPool
    // ──────────────────────────────────────────────

    function test_registerPool_success() public {
        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit PoolRegistered(poolId, address(pool));
        manager.registerPool(poolId, address(pool));

        assertEq(uint256(manager.getSettlementStatus(poolId)), uint256(ISettlementManager.SettlementStatus.Pending));
    }

    function test_registerPool_revertNotOwner() public {
        vm.prank(stranger);
        vm.expectRevert();
        manager.registerPool(poolId, address(pool));
    }

    function test_registerPool_revertZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(ISettlementManager.ZeroAddress.selector);
        manager.registerPool(poolId, address(0));
    }

    function test_registerPool_revertDuplicate() public {
        vm.prank(owner);
        manager.registerPool(poolId, address(pool));

        vm.prank(owner);
        vm.expectRevert(ISettlementManager.PoolAlreadyRegistered.selector);
        manager.registerPool(poolId, address(pool));
    }

    // ──────────────────────────────────────────────
    //  scheduleSettlement
    // ──────────────────────────────────────────────

    function test_scheduleSettlement_success() public {
        vm.prank(owner);
        manager.registerPool(poolId, address(pool));

        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit SettlementScheduled(poolId, settlementDeadline);
        manager.scheduleSettlement(poolId, settlementDeadline);
    }

    function test_scheduleSettlement_revertNotOwner() public {
        vm.prank(owner);
        manager.registerPool(poolId, address(pool));

        vm.prank(stranger);
        vm.expectRevert();
        manager.scheduleSettlement(poolId, settlementDeadline);
    }

    function test_scheduleSettlement_revertPoolNotFound() public {
        vm.prank(owner);
        vm.expectRevert(ISettlementManager.PoolNotFound.selector);
        manager.scheduleSettlement(poolId, settlementDeadline);
    }

    function test_scheduleSettlement_revertAlreadyScheduled() public {
        vm.prank(owner);
        manager.registerPool(poolId, address(pool));

        vm.prank(owner);
        manager.scheduleSettlement(poolId, settlementDeadline);

        vm.prank(owner);
        vm.expectRevert(ISettlementManager.SettlementAlreadyScheduled.selector);
        manager.scheduleSettlement(poolId, settlementDeadline);
    }

    // ──────────────────────────────────────────────
    //  executeSettlement
    // ──────────────────────────────────────────────

    function test_executeSettlement_success() public {
        _setupSettlement();

        // User buys a position so payout works
        vm.deal(user, 10 ether);
        vm.prank(user);
        pool.buyPosition{value: 10 ether}(IPredictionPool.Side.YES, 10 ether);

        // Warp past settlement deadline
        vm.warp(settlementDeadline + 1);

        vm.prank(oracle);
        vm.expectEmit(true, true, false, true);
        emit SettlementExecuted(poolId, true);
        manager.executeSettlement(poolId, true);

        assertTrue(pool.isResolved());
        assertEq(uint256(manager.getSettlementStatus(poolId)), uint256(ISettlementManager.SettlementStatus.Executed));
    }

    function test_executeSettlement_revertNotOracle() public {
        _setupSettlement();

        vm.prank(stranger);
        vm.expectRevert(ISettlementManager.InvalidOracleData.selector);
        manager.executeSettlement(poolId, true);
    }

    function test_executeSettlement_revertPoolNotFound() public {
        vm.prank(oracle);
        vm.expectRevert(ISettlementManager.PoolNotFound.selector);
        manager.executeSettlement(poolId, true);
    }

    function test_executeSettlement_revertNotReady() public {
        _setupSettlement();

        // Haven't warped past deadline
        vm.prank(oracle);
        vm.expectRevert(ISettlementManager.SettlementNotReady.selector);
        manager.executeSettlement(poolId, true);
    }

    function test_executeSettlement_revertAlreadyExecuted() public {
        _setupSettlement();
        vm.warp(settlementDeadline + 1);

        vm.prank(oracle);
        manager.executeSettlement(poolId, true);

        vm.prank(oracle);
        vm.expectRevert(ISettlementManager.AlreadyExecuted.selector);
        manager.executeSettlement(poolId, true);
    }

    // ──────────────────────────────────────────────
    //  getSettlementStatus
    // ──────────────────────────────────────────────

    function test_getSettlementStatus_pendingAfterSchedule() public {
        vm.prank(owner);
        manager.registerPool(poolId, address(pool));

        vm.prank(owner);
        manager.scheduleSettlement(poolId, settlementDeadline);

        assertEq(uint256(manager.getSettlementStatus(poolId)), uint256(ISettlementManager.SettlementStatus.Pending));
    }

    function test_getSettlementStatus_executedAfterExecute() public {
        _setupSettlement();
        vm.warp(settlementDeadline + 1);

        vm.prank(oracle);
        manager.executeSettlement(poolId, true);

        assertEq(uint256(manager.getSettlementStatus(poolId)), uint256(ISettlementManager.SettlementStatus.Executed));
    }

    // ──────────────────────────────────────────────
    //  Integration: full end-to-end flow
    // ──────────────────────────────────────────────

    function test_integration_fullFlow() public {
        // 1. Register pool + schedule settlement
        vm.prank(owner);
        manager.registerPool(poolId, address(pool));

        vm.prank(owner);
        manager.scheduleSettlement(poolId, settlementDeadline);

        // 2. Users buy positions
        address user2 = makeAddr("user2");
        vm.deal(user, 5 ether);
        vm.deal(user2, 3 ether);

        vm.prank(user);
        pool.buyPosition{value: 5 ether}(IPredictionPool.Side.YES, 5 ether);

        vm.prank(user2);
        pool.buyPosition{value: 3 ether}(IPredictionPool.Side.NO, 3 ether);

        // 3. Warp past settlement deadline
        vm.warp(settlementDeadline + 1);

        // 4. Execute settlement (YES wins)
        vm.prank(oracle);
        manager.executeSettlement(poolId, true);

        // 5. Verify pool resolved correctly
        IPredictionPool.PoolInfo memory info = pool.getPoolInfo();
        assertEq(uint256(info.status), uint256(IPredictionPool.PoolStatus.Resolved));
        assertEq(uint256(info.winningSide), uint256(IPredictionPool.Side.YES));
        assertEq(info.yesPool, 5 ether);
        assertEq(info.noPool, 3 ether);

        // 6. YES user claims proportional payout
        uint256 claimAmount = pool.claim(user);
        // (5 / 5) * 8 = 8 ether (YES user gets all since they own all YES)
        assertEq(claimAmount, 8 ether);

        // 7. NO user claims nothing (losing side)
        vm.expectRevert(PredictionPool.NothingToClaim.selector);
        pool.claim(user2);
    }

    // ──────────────────────────────────────────────
    //  Fuzz
    // ──────────────────────────────────────────────

    function testFuzz_executeSettlement(uint256 warpTime) public {
        warpTime = bound(warpTime, settlementDeadline + 1, poolDeadline - 1);

        _setupSettlement();

        vm.deal(user, 10 ether);
        vm.prank(user);
        pool.buyPosition{value: 10 ether}(IPredictionPool.Side.YES, 10 ether);

        vm.warp(warpTime);

        vm.prank(oracle);
        manager.executeSettlement(poolId, true);

        assertTrue(pool.isResolved());
        assertEq(uint256(manager.getSettlementStatus(poolId)), uint256(ISettlementManager.SettlementStatus.Executed));
    }

    // ──────────────────────────────────────────────
    //  Helpers
    // ──────────────────────────────────────────────

    function _setupSettlement() internal {
        vm.prank(owner);
        manager.registerPool(poolId, address(pool));

        vm.prank(owner);
        manager.scheduleSettlement(poolId, settlementDeadline);
    }
}
