// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface ISettlementManager {
    enum SettlementStatus {
        Pending,
        Executed,
        Failed
    }

    function registerPool(bytes32 poolId, address pool) external;
    function scheduleSettlement(bytes32 poolId, uint256 deadline) external;
    function executeSettlement(bytes32 poolId, bool outcome) external;
    function getSettlementStatus(bytes32 poolId) external view returns (SettlementStatus);

    event PoolRegistered(bytes32 indexed poolId, address indexed pool);
    event SettlementScheduled(bytes32 indexed poolId, uint256 deadline);
    event SettlementExecuted(bytes32 indexed poolId, bool outcome);
    event SettlementFailed(bytes32 indexed poolId, string reason);

    error PoolNotFound();
    error SettlementAlreadyScheduled();
    error SettlementNotReady();
    error InvalidOracleData();
    error ZeroAddress();
}
