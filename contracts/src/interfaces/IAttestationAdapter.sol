// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title Attestation Adapter Interface
/// @notice Records settlement results as on-chain attestations for agent track record
/// @dev MVP stores in-contract; real EAS integration gated behind ponytail
interface IAttestationAdapter {
    /// @notice Attestation data for a resolved pool
    /// @param poolId Unique pool identifier
    /// @param predictedOutcome What the AI predicted (true = rug)
    /// @param actualOutcome What actually happened (true = rug)
    /// @param timestamp Block timestamp when attestation was recorded
    /// @param uid Unique attestation identifier (computed from pool data)
    struct Attestation {
        bytes32 poolId;
        bool predictedOutcome;
        bool actualOutcome;
        uint256 timestamp;
        bytes32 uid;
    }

    /// @notice Record attestation for a resolved prediction pool. One-time per pool.
    /// @param poolId Unique pool identifier
    /// @param predictedOutcome What the AI predicted (true = rug)
    /// @param actualOutcome What actually happened (true = rug)
    /// @return uid Unique attestation identifier
    /// @custom:emits Attested
    function attestResult(bytes32 poolId, bool predictedOutcome, bool actualOutcome) external returns (bytes32 uid);

    /// @notice Get attestation for a pool
    /// @param poolId Unique pool identifier
    /// @return Attestation struct (poolId, predictedOutcome, actualOutcome, timestamp, uid)
    /// @dev Returns zeroed struct if pool has not been attested
    function getAttestation(bytes32 poolId) external view returns (Attestation memory);

    event Attested(bytes32 indexed poolId, bytes32 indexed easUid, bool predicted, bool actual);

    error AttestationAlreadyExists();
    error EASContractError();
    error PoolNotFound();
}
