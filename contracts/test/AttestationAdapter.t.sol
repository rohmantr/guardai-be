// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console2} from "forge-std/Test.sol";
import {IAttestationAdapter} from "../src/interfaces/IAttestationAdapter.sol";
import {AttestationAdapter} from "../src/core/AttestationAdapter.sol";

contract AttestationAdapterTest is Test {
    AttestationAdapter public adapter;
    address public owner = makeAddr("owner");
    address public stranger = makeAddr("stranger");
    bytes32 public poolId = keccak256("pool-1");

    event Attested(bytes32 indexed poolId, bytes32 indexed easUid, bool predicted, bool actual);

    function setUp() public {
        vm.prank(owner);
        adapter = new AttestationAdapter();
    }

    function test_attestResult_success() public {
        vm.prank(owner);
        // easUid is computed inside attestResult, so we don't check topic2
        vm.expectEmit(true, false, false, true);
        emit Attested(poolId, bytes32(0), true, false);
        bytes32 uid = adapter.attestResult(poolId, true, false);

        assertTrue(uid != bytes32(0));

        IAttestationAdapter.Attestation memory a = adapter.getAttestation(poolId);
        assertEq(a.poolId, poolId);
        assertEq(a.predictedOutcome, true);
        assertEq(a.actualOutcome, false);
        assertEq(a.uid, uid);
        assertGt(a.timestamp, 0);
    }

    function test_attestResult_revertAlreadyExists() public {
        vm.prank(owner);
        adapter.attestResult(poolId, true, true);

        vm.prank(owner);
        vm.expectRevert(IAttestationAdapter.AttestationAlreadyExists.selector);
        adapter.attestResult(poolId, false, true);
    }

    function test_attestResult_revertNonOwner() public {
        vm.prank(stranger);
        vm.expectRevert();
        adapter.attestResult(poolId, true, false);
    }

    function test_getAttestation_returnsZeroedBeforeAttestation() public {
        IAttestationAdapter.Attestation memory a = adapter.getAttestation(poolId);
        assertEq(a.uid, bytes32(0));
        assertEq(a.timestamp, 0);
    }

    function testFuzz_attestResult(bool predictedOutcome, bool actualOutcome) public {
        vm.prank(owner);
        bytes32 uid = adapter.attestResult(poolId, predictedOutcome, actualOutcome);

        IAttestationAdapter.Attestation memory a = adapter.getAttestation(poolId);
        assertEq(a.predictedOutcome, predictedOutcome);
        assertEq(a.actualOutcome, actualOutcome);
        assertEq(a.uid, uid);
        assertGt(a.timestamp, 0);
    }
}
