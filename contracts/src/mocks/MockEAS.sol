// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title MockEAS
/// @notice Minimal mock of Ethereum Attestation Service for testing
/// @dev Use in tests to verify EAS integration path when swapped in for MVP storage
/// ponytail: replace with IEAS (npm: ethereum-attestation-service) when integrating real EAS
contract MockEAS {
    struct AttestationRecord {
        bytes32 schema;
        bytes32 uid;
        bytes data;
    }

    mapping(bytes32 => AttestationRecord) public attestations;

    /// @notice Simulate EAS attest() — store data and return a deterministic uid
    /// @param schema Schema UID (unused in mock, stored for interface compatibility)
    /// @param data ABI-encoded attestation payload
    /// @return uid Deterministic uid based on schema and data
    function attest(bytes32 schema, bytes calldata data) external returns (bytes32 uid) {
        uid = keccak256(abi.encodePacked(schema, data, block.timestamp));
        attestations[uid] = AttestationRecord({schema: schema, uid: uid, data: data});
    }

    /// @notice Simulate EAS getAttestation() — retrieve stored attestation
    /// @param uid Attestation UID
    /// @return AttestationRecord struct
    function getAttestation(bytes32 uid) external view returns (AttestationRecord memory) {
        return attestations[uid];
    }
}
