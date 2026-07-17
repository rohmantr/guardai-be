// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IOracleAdapter {
    struct ResolutionData {
        bool liquidityPulled;
        uint256 timestamp;
        bytes32 txHash;
    }

    function reportLiquidityPull(bytes32 poolId, address tokenAddress, bytes calldata proof) external;
    function isResolved(bytes32 poolId) external view returns (bool);
    function getResolutionData(bytes32 poolId) external view returns (ResolutionData memory);

    event LiquidityPullReported(bytes32 indexed poolId, address indexed token, uint256 timestamp);
    event OracleUpdated(address indexed oldOracle, address indexed newOracle);

    error AlreadyResolved();
    error InvalidProof();
    error NotTrustedRelayer();
}
