// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {IOracleAdapter} from "../src/interfaces/IOracleAdapter.sol";
import {OracleAdapter} from "../src/oracle/OracleAdapter.sol";

contract OracleAdapterTest is Test {
    OracleAdapter public adapter;
    address public owner = makeAddr("owner");
    address public stranger = makeAddr("stranger");
    address public tokenA = makeAddr("tokenA");
    bytes32 public poolId = keccak256("pool-1");
    bytes32 public poolId2 = keccak256("pool-2");
    bytes public emptyProof = "";

    event LiquidityPullReported(bytes32 indexed poolId, address indexed token, uint256 timestamp);
    event OracleUpdated(address indexed oldOracle, address indexed newOracle);

    function setUp() public {
        vm.prank(owner);
        adapter = new OracleAdapter();
    }

    // ──────────────────────────────────────────────
    //  reportLiquidityPull
    // ──────────────────────────────────────────────

    function test_reportLiquidityPull_success() public {
        vm.prank(owner);

        vm.expectEmit(true, true, false, true);
        emit LiquidityPullReported(poolId, tokenA, block.timestamp);

        adapter.reportLiquidityPull(poolId, tokenA, emptyProof);

        assertTrue(adapter.isResolved(poolId));

        IOracleAdapter.ResolutionData memory data = adapter.getResolutionData(poolId);
        assertTrue(data.liquidityPulled);
        assertEq(data.timestamp, block.timestamp);
        assertEq(data.txHash, keccak256(abi.encode(poolId, tokenA, block.timestamp)));
    }

    function test_reportLiquidityPull_revertNotOwner() public {
        vm.prank(stranger);
        vm.expectRevert();
        adapter.reportLiquidityPull(poolId, tokenA, emptyProof);
    }

    function test_reportLiquidityPull_revertAlreadyResolved() public {
        vm.prank(owner);
        adapter.reportLiquidityPull(poolId, tokenA, emptyProof);

        vm.prank(owner);
        vm.expectRevert(IOracleAdapter.AlreadyResolved.selector);
        adapter.reportLiquidityPull(poolId, tokenA, emptyProof);
    }

    function test_reportLiquidityPull_multiplePools() public {
        vm.prank(owner);
        adapter.reportLiquidityPull(poolId, tokenA, emptyProof);

        vm.prank(owner);
        adapter.reportLiquidityPull(poolId2, tokenA, emptyProof);

        assertTrue(adapter.isResolved(poolId));
        assertTrue(adapter.isResolved(poolId2));
    }

    // ──────────────────────────────────────────────
    //  isResolved
    // ──────────────────────────────────────────────

    function test_isResolved_falseWhenNotResolved() public {
        assertFalse(adapter.isResolved(poolId));
    }

    function test_isResolved_trueAfterReport() public {
        vm.prank(owner);
        adapter.reportLiquidityPull(poolId, tokenA, emptyProof);

        assertTrue(adapter.isResolved(poolId));
    }

    // ──────────────────────────────────────────────
    //  getResolutionData
    // ──────────────────────────────────────────────

    function test_getResolutionData_zeroWhenNotResolved() public {
        IOracleAdapter.ResolutionData memory data = adapter.getResolutionData(poolId);
        assertFalse(data.liquidityPulled);
        assertEq(data.timestamp, 0);
        assertEq(data.txHash, bytes32(0));
    }

    // ──────────────────────────────────────────────
    //  setOracle
    // ──────────────────────────────────────────────

    function test_setOracle_success() public {
        address newOracle = makeAddr("newOracle");

        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit OracleUpdated(address(0), newOracle);

        adapter.setOracle(newOracle);
        assertEq(adapter.oracle(), newOracle);
    }

    function test_setOracle_revertNotOwner() public {
        vm.prank(stranger);
        vm.expectRevert();
        adapter.setOracle(makeAddr("newOracle"));
    }

    // ──────────────────────────────────────────────
    //  Fuzz tests
    // ──────────────────────────────────────────────

    function testFuzz_reportLiquidityPull(bytes32 _poolId) public {
        // Ensure pool not already resolved from another fuzz run
        vm.assume(!adapter.isResolved(_poolId));

        vm.prank(owner);
        adapter.reportLiquidityPull(_poolId, tokenA, emptyProof);

        assertTrue(adapter.isResolved(_poolId));

        IOracleAdapter.ResolutionData memory data = adapter.getResolutionData(_poolId);
        assertTrue(data.liquidityPulled);
        assertEq(data.timestamp, block.timestamp);
    }
}
