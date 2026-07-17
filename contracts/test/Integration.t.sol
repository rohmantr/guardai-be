// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {IPredictionPool} from "../src/interfaces/IPredictionPool.sol";
import {ISettlementManager} from "../src/interfaces/ISettlementManager.sol";
import {ITreasury} from "../src/interfaces/ITreasury.sol";
import {IRiskRegistry} from "../src/interfaces/IRiskRegistry.sol";
import {IAttestationAdapter} from "../src/interfaces/IAttestationAdapter.sol";
import {PredictionPool} from "../src/core/PredictionPool.sol";
import {Treasury} from "../src/core/Treasury.sol";
import {RiskRegistry} from "../src/core/RiskRegistry.sol";
import {OracleAdapter} from "../src/oracle/OracleAdapter.sol";
import {SettlementManager} from "../src/settlement/SettlementManager.sol";
import {AttestationAdapter} from "../src/core/AttestationAdapter.sol";

/// @title IntegrationTest
/// @notice End-to-end integration tests simulating full Rug Radar flow
/// @dev Wallets can be loaded from the environment or default to generated test addresses.
/// @custom:security Tests cover CEI, access control, edge cases, and fuzzing
contract IntegrationTest is Test {
    address internal owner;
    address internal agent;
    address internal oracle;

    PredictionPool internal pool;
    Treasury internal treasury;
    RiskRegistry internal riskRegistry;
    OracleAdapter internal oracleAdapter;
    SettlementManager internal settlementManager;
    AttestationAdapter internal attestationAdapter;

    address internal traderA;
    address internal traderB;
    address internal stranger;

    bytes32 internal constant POOL_ID = keccak256("integration-pool-001");
    address internal constant TOKEN = address(0xCAFE);
    uint256 internal poolDeadline;
    uint256 internal settlementDeadline;

    event PoolCreated(bytes32 indexed poolId, address indexed token, uint256 deadline);
    event AssessmentRecorded(address indexed token, uint256 probability, bytes32 indexed assessmentId);
    event PoolRegistered(address indexed pool, bytes32 indexed poolId);
    event PositionPurchased(bytes32 indexed poolId, address indexed user, IPredictionPool.Side side, uint256 amount);
    event LiquidityPullReported(bytes32 indexed poolId, address indexed token, uint256 timestamp);
    event SettlementScheduled(bytes32 indexed poolId, uint256 deadline);
    event SettlementExecuted(bytes32 indexed poolId, bool outcome);
    event PoolResolved(bytes32 indexed poolId, IPredictionPool.Side winningSide, uint256 totalYes, uint256 totalNo);
    event ClaimExecuted(bytes32 indexed poolId, address indexed user, uint256 payout);
    event Deposited(bytes32 indexed poolId, address indexed pool, uint256 amount);
    event Attested(bytes32 indexed poolId, bytes32 indexed easUid, bool predicted, bool actual);

    function setUp() public {
        traderA = makeAddr("traderA");
        traderB = makeAddr("traderB");
        stranger = makeAddr("stranger");

        owner = vm.envOr("OWNER_ADDRESS", makeAddr("owner"));
        agent = vm.envOr("AGENT_ADDRESS", makeAddr("agent"));
        oracle = vm.envOr("ORACLE_ADDRESS", makeAddr("oracle"));

        poolDeadline = block.timestamp + 14 days;
        settlementDeadline = block.timestamp + 1 days;

        vm.startPrank(owner);

        treasury = new Treasury();
        riskRegistry = new RiskRegistry();
        oracleAdapter = new OracleAdapter();
        settlementManager = new SettlementManager(oracle);
        attestationAdapter = new AttestationAdapter();

        pool = new PredictionPool(POOL_ID, TOKEN, address(settlementManager), poolDeadline);

        settlementManager.registerPool(POOL_ID, address(pool));
        settlementManager.scheduleSettlement(POOL_ID, settlementDeadline);
        treasury.registerPool(address(pool), POOL_ID);
        riskRegistry.setAgent(agent);

        vm.stopPrank();

        vm.prank(agent);
        riskRegistry.recordAssessment(TOKEN, 8000, keccak256("assessment-001"));
    }

    function _fundAndBuy(IPredictionPool.Side side, uint256 amount, address trader) internal {
        vm.deal(trader, amount);
        vm.prank(trader);
        pool.buyPosition{value: amount}(side, amount);
    }

    function _settle(bool outcome) internal {
        vm.warp(settlementDeadline + 1);
        vm.prank(oracle);
        settlementManager.executeSettlement(POOL_ID, outcome);
    }

    function test_yesWins_fullFlow() public {
        vm.prank(owner);
        oracleAdapter.reportLiquidityPull(POOL_ID, TOKEN, "");

        assertTrue(oracleAdapter.isResolved(POOL_ID));

        _fundAndBuy(IPredictionPool.Side.YES, 100 ether, traderA);
        _fundAndBuy(IPredictionPool.Side.NO, 100 ether, traderB);

        assertEq(pool.yesPool(), 100 ether);
        assertEq(pool.noPool(), 100 ether);

        _settle(true);

        IPredictionPool.PoolInfo memory info = pool.getPoolInfo();
        assertEq(uint256(info.status), uint256(IPredictionPool.PoolStatus.Resolved));
        assertEq(uint256(info.winningSide), uint256(IPredictionPool.Side.YES));
        assertEq(
            uint256(settlementManager.getSettlementStatus(POOL_ID)),
            uint256(ISettlementManager.SettlementStatus.Executed)
        );

        uint256 payoutA = pool.claim(traderA);
        assertEq(payoutA, 200 ether);

        vm.expectRevert(PredictionPool.NothingToClaim.selector);
        pool.claim(traderB);
    }

    function test_noWins_fullFlow() public {
        _fundAndBuy(IPredictionPool.Side.YES, 50 ether, traderA);
        _fundAndBuy(IPredictionPool.Side.NO, 150 ether, traderB);

        _settle(false); // NO wins

        IPredictionPool.PoolInfo memory info = pool.getPoolInfo();
        assertEq(uint256(info.winningSide), uint256(IPredictionPool.Side.NO));

        uint256 payoutB = pool.claim(traderB);
        assertEq(payoutB, 200 ether);

        vm.expectRevert(PredictionPool.NothingToClaim.selector);
        pool.claim(traderA);
    }

    function test_proportionalPayout_splitYes() public {
        address traderC = makeAddr("traderC");

        _fundAndBuy(IPredictionPool.Side.YES, 25 ether, traderA);
        _fundAndBuy(IPredictionPool.Side.YES, 75 ether, traderB);
        _fundAndBuy(IPredictionPool.Side.NO, 100 ether, traderC);

        _settle(true); // YES wins

        assertEq(pool.claim(traderA), 50 ether);
        assertEq(pool.claim(traderB), 150 ether);

        // NO holder gets nothing
        vm.expectRevert(PredictionPool.NothingToClaim.selector);
        pool.claim(traderC);
    }

    function test_edge_buyAfterDeadline() public {
        vm.warp(poolDeadline + 1);
        vm.deal(traderA, 1 ether);
        vm.prank(traderA);
        vm.expectRevert(PredictionPool.PoolAlreadyExpired.selector);
        pool.buyPosition{value: 1 ether}(IPredictionPool.Side.YES, 1 ether);
    }

    function test_edge_doubleClaim() public {
        _fundAndBuy(IPredictionPool.Side.YES, 10 ether, traderA);
        _fundAndBuy(IPredictionPool.Side.NO, 10 ether, traderB);
        _settle(true);

        pool.claim(traderA);
        vm.expectRevert(PredictionPool.AlreadyClaimed.selector);
        pool.claim(traderA);
    }

    function test_edge_doubleSettlement() public {
        _fundAndBuy(IPredictionPool.Side.YES, 10 ether, traderA);
        _settle(true);

        vm.prank(oracle);
        vm.expectRevert(ISettlementManager.AlreadyExecuted.selector);
        settlementManager.executeSettlement(POOL_ID, true);
    }

    function test_edge_nonOracleCannotSettle() public {
        _fundAndBuy(IPredictionPool.Side.YES, 10 ether, traderA);
        vm.warp(settlementDeadline + 1);

        vm.prank(stranger);
        vm.expectRevert(ISettlementManager.InvalidOracleData.selector);
        settlementManager.executeSettlement(POOL_ID, true);
    }

    function test_edge_emptyPoolSettle() public {
        vm.warp(settlementDeadline + 1);
        vm.prank(oracle);
        settlementManager.executeSettlement(POOL_ID, true);

        assertTrue(pool.isResolved());

        vm.expectRevert(PredictionPool.NothingToClaim.selector);
        pool.claim(traderA);
    }

    function test_edge_buyAfterSettlement() public {
        _fundAndBuy(IPredictionPool.Side.YES, 10 ether, traderA);

        vm.warp(settlementDeadline + 1);
        vm.prank(oracle);
        settlementManager.executeSettlement(POOL_ID, true);

        vm.deal(traderB, 5 ether);
        vm.prank(traderB);
        vm.expectRevert(PredictionPool.PoolNotActive.selector);
        pool.buyPosition{value: 5 ether}(IPredictionPool.Side.NO, 5 ether);
    }

    function test_treasury_integration() public {
        vm.prank(owner);
        treasury.setFeeBps(500); // 5%

        vm.deal(address(pool), 100 ether);
        vm.prank(address(pool));
        treasury.deposit{value: 100 ether}();

        assertEq(treasury.getBalance(POOL_ID), 95 ether);

        vm.prank(address(pool));
        treasury.payout(traderA, 50 ether);
        assertEq(treasury.getBalance(POOL_ID), 45 ether);

        uint256 before = owner.balance;
        vm.prank(owner);
        treasury.withdrawFees(owner, 5 ether);
        assertEq(owner.balance, before + 5 ether);
    }

    function test_riskRegistry_integration() public {
        assertTrue(riskRegistry.assessmentExists(TOKEN));

        IRiskRegistry.RiskAssessment memory a = riskRegistry.getAssessment(TOKEN);
        assertEq(a.probability, 8000);
        assertEq(a.assessmentId, keccak256("assessment-001"));
        assertTrue(a.timestamp > 0);
    }

    function test_attestationAdapter_integration() public {
        vm.prank(owner);
        bytes32 uid = attestationAdapter.attestResult(POOL_ID, true, true);
        assertTrue(uid != bytes32(0));

        IAttestationAdapter.Attestation memory att = attestationAdapter.getAttestation(POOL_ID);
        assertEq(att.poolId, POOL_ID);
        assertTrue(att.predictedOutcome);
        assertTrue(att.actualOutcome);
    }

    function test_access_oracleAdapterCannotSettle() public {
        _fundAndBuy(IPredictionPool.Side.YES, 10 ether, traderA);
        vm.warp(settlementDeadline + 1);

        vm.prank(address(oracleAdapter));
        vm.expectRevert(ISettlementManager.InvalidOracleData.selector);
        settlementManager.executeSettlement(POOL_ID, true);
    }

    function testFuzz_BuyAndSettle_ProportionalPayout(uint256 yesAmount, uint256 noAmount) public {
        yesAmount = bound(yesAmount, 0.01 ether, 1000 ether);
        noAmount = bound(noAmount, 0.01 ether, 1000 ether);

        _fundAndBuy(IPredictionPool.Side.YES, yesAmount, traderA);
        _fundAndBuy(IPredictionPool.Side.NO, noAmount, traderB);

        _settle(true);

        uint256 totalPool = yesAmount + noAmount;
        assertEq(pool.claim(traderA), totalPool);

        vm.expectRevert(PredictionPool.NothingToClaim.selector);
        pool.claim(traderB);
    }

    function testFuzz_BuyAndSettle_MultipleYesHolders(uint256 a, uint256 b, uint256 no) public {
        a = bound(a, 0.01 ether, 1000 ether);
        b = bound(b, 0.01 ether, 1000 ether);
        no = bound(no, 0.01 ether, 1000 ether);

        address traderC = makeAddr("traderC");

        _fundAndBuy(IPredictionPool.Side.YES, a, traderA);
        _fundAndBuy(IPredictionPool.Side.YES, b, traderB);
        _fundAndBuy(IPredictionPool.Side.NO, no, traderC);

        _settle(true);

        uint256 total = a + b + no;
        uint256 totalYes = a + b;

        assertEq(pool.claim(traderA), (a * total) / totalYes);
        assertEq(pool.claim(traderB), (b * total) / totalYes);

        vm.expectRevert(PredictionPool.NothingToClaim.selector);
        pool.claim(traderC);
    }
}
