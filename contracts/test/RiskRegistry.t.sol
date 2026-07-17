// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console2} from "forge-std/Test.sol";
import {IRiskRegistry} from "../src/interfaces/IRiskRegistry.sol";
import {RiskRegistry} from "../src/core/RiskRegistry.sol";

contract RiskRegistryTest is Test {
    RiskRegistry public registry;
    address public owner = makeAddr("owner");
    address public agent = makeAddr("agent");
    address public stranger = makeAddr("stranger");
    address public tokenA = makeAddr("tokenA");
    address public tokenB = makeAddr("tokenB");
    bytes32 public assessmentId = keccak256("assessment-1");

    event AssessmentRecorded(address indexed token, uint256 probability, bytes32 indexed assessmentId);

    function setUp() public {
        vm.prank(owner);
        registry = new RiskRegistry();
        vm.prank(owner);
        registry.setAgent(agent);
    }

    function test_recordAssessment_success() public {
        vm.prank(agent);
        vm.expectEmit(true, true, false, true);
        emit AssessmentRecorded(tokenA, 7500, assessmentId);
        registry.recordAssessment(tokenA, 7500, assessmentId);

        IRiskRegistry.RiskAssessment memory a = registry.getAssessment(tokenA);
        assertEq(a.probability, 7500);
        assertEq(a.assessmentId, assessmentId);
        assertGt(a.timestamp, 0);
        assertTrue(registry.assessmentExists(tokenA));
    }

    function test_recordAssessment_revertAlreadyExists() public {
        vm.prank(agent);
        registry.recordAssessment(tokenA, 5000, assessmentId);

        vm.prank(agent);
        vm.expectRevert(IRiskRegistry.AssessmentAlreadyExists.selector);
        registry.recordAssessment(tokenA, 6000, keccak256("assessment-2"));
    }

    function test_recordAssessment_revertInvalidProbabilityAboveMax() public {
        vm.prank(agent);
        vm.expectRevert(IRiskRegistry.InvalidProbability.selector);
        registry.recordAssessment(tokenA, 10001, assessmentId);
    }

    function test_recordAssessment_revertNotAuthorizedAgent() public {
        vm.prank(stranger);
        vm.expectRevert(IRiskRegistry.NotAuthorizedAgent.selector);
        registry.recordAssessment(tokenA, 5000, assessmentId);
    }

    function test_recordAssessment_probabilityZero() public {
        vm.prank(agent);
        registry.recordAssessment(tokenA, 0, assessmentId);
        assertEq(registry.getAssessment(tokenA).probability, 0);
        assertTrue(registry.assessmentExists(tokenA));
    }

    function test_recordAssessment_probabilityMax() public {
        vm.prank(agent);
        registry.recordAssessment(tokenA, 10000, assessmentId);
        assertEq(registry.getAssessment(tokenA).probability, 10000);
    }

    function test_setAgent_success() public {
        address newAgent = makeAddr("newAgent");
        vm.prank(owner);
        registry.setAgent(newAgent);
        assertEq(registry.agent(), newAgent);
    }

    function test_setAgent_revertNonOwner() public {
        vm.prank(stranger);
        vm.expectRevert(); // Ownable's onlyOwner modifier
        registry.setAgent(stranger);
    }

    function test_getAssessment_returnsCorrectData() public {
        vm.prank(agent);
        registry.recordAssessment(tokenA, 3200, assessmentId);

        IRiskRegistry.RiskAssessment memory a = registry.getAssessment(tokenA);
        assertEq(a.probability, 3200);
        assertEq(a.assessmentId, assessmentId);
        assertEq(a.timestamp, block.timestamp);
    }

    function test_assessmentExists_returnsTrue() public {
        vm.prank(agent);
        registry.recordAssessment(tokenA, 5000, assessmentId);
        assertTrue(registry.assessmentExists(tokenA));
    }

    function test_assessmentExists_returnsFalse() public {
        assertFalse(registry.assessmentExists(tokenA));
        assertFalse(registry.assessmentExists(tokenB));
    }

    function test_recordAssessment_multipleTokens() public {
        vm.prank(agent);
        registry.recordAssessment(tokenA, 1000, keccak256("a"));
        vm.prank(agent);
        registry.recordAssessment(tokenB, 9000, keccak256("b"));

        assertTrue(registry.assessmentExists(tokenA));
        assertTrue(registry.assessmentExists(tokenB));
        assertEq(registry.getAssessment(tokenA).probability, 1000);
        assertEq(registry.getAssessment(tokenB).probability, 9000);
    }
}
