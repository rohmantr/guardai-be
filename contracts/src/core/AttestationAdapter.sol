// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/access/Ownable2Step.sol";
import {IAttestationAdapter} from "../interfaces/IAttestationAdapter.sol";

/// @title AttestationAdapter
/// @notice Records settlement results as on-chain attestations for agent track record
/// @dev MVP stores attestations in-contract. One attestation per pool — immutable after write.
///      Real EAS call gated behind ponytail: when EAS is deployed on Base, replace storage with IEAS.attest().
/// @custom:security Ownable2Step prevents ownership misuse; one-time write per pool prevents overwrite
contract AttestationAdapter is IAttestationAdapter, Ownable2Step {
    mapping(bytes32 => Attestation) private s_attestations;

    constructor() Ownable(msg.sender) {}

    /// @notice Record attestation for a resolved pool. One-time per pool.
    /// @param poolId Unique pool identifier
    /// @param predictedOutcome What the AI predicted (true = rug)
    /// @param actualOutcome What actually happened (true = rug)
    /// @return uid Unique attestation identifier
    /// @custom:security Immutable write — no update or delete path
    /// @custom:emits Attested
    function attestResult(bytes32 poolId, bool predictedOutcome, bool actualOutcome)
        external
        onlyOwner
        returns (bytes32 uid)
    {
        if (s_attestations[poolId].uid != bytes32(0)) revert AttestationAlreadyExists();

        uid = keccak256(abi.encodePacked(poolId, predictedOutcome, actualOutcome, block.timestamp));
        s_attestations[poolId] = Attestation({
            poolId: poolId,
            predictedOutcome: predictedOutcome,
            actualOutcome: actualOutcome,
            timestamp: block.timestamp,
            uid: uid
        });

        emit Attested(poolId, uid, predictedOutcome, actualOutcome);
    }

    /// @notice Get attestation for a pool
    /// @param poolId Unique pool identifier
    /// @return Attestation struct (poolId, predictedOutcome, actualOutcome, timestamp, uid)
    /// @dev Returns zeroed struct if pool has not been attested
    /// ponytail: add PoolNotFound revert when pool registry exists
    function getAttestation(bytes32 poolId) external view returns (Attestation memory) {
        return s_attestations[poolId];
    }
}
