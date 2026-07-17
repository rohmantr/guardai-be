// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/access/Ownable2Step.sol";
import {IPredictionPool} from "../interfaces/IPredictionPool.sol";
import {ISettlementManager} from "../interfaces/ISettlementManager.sol";

/// @title SettlementManager
/// @notice Orchestrates settlement between OracleAdapter and PredictionPool
/// @dev Two-step flow: OracleAdapter triggers executeSettlement → calls PredictionPool.settle
/// @custom:security Ownable2Step, onlyOracle access control
contract SettlementManager is ISettlementManager, Ownable2Step {
    struct SettlementInfo {
        address pool;
        uint256 deadline;
        SettlementStatus status;
    }

    mapping(bytes32 => SettlementInfo) private _settlements;

    address public oracle;

    /// @param _oracle Address of the OracleAdapter contract
    constructor(address _oracle) Ownable(msg.sender) {
        oracle = _oracle;
    }

    /// @notice Registers a PredictionPool address for a poolId
    /// @param poolId Pool identifier
    /// @param pool PredictionPool contract address
    /// @custom:emits PoolRegistered
    function registerPool(bytes32 poolId, address pool) external onlyOwner {
        if (pool == address(0)) revert ZeroAddress();
        if (_settlements[poolId].pool != address(0)) revert SettlementAlreadyScheduled();

        _settlements[poolId].pool = pool;
        emit PoolRegistered(poolId, pool);
    }

    /// @notice Schedules a settlement for a pool with a deadline
    /// @param poolId Pool identifier
    /// @param deadline Timestamp before which settlement cannot be executed
    /// @custom:security Reverts if pool not registered or already scheduled
    /// @custom:emits SettlementScheduled
    function scheduleSettlement(bytes32 poolId, uint256 deadline) external onlyOwner {
        SettlementInfo storage info = _settlements[poolId];
        if (info.pool == address(0)) revert PoolNotFound();
        if (info.deadline != 0) revert SettlementAlreadyScheduled();

        info.deadline = deadline;
        emit SettlementScheduled(poolId, deadline);
    }

    /// @notice Executes settlement by calling PredictionPool.settle
    /// @param poolId Pool identifier
    /// @param outcome true = YES wins (liquidity pulled), false = NO wins
    /// @custom:security CEI: status update before external call
    /// @custom:emits SettlementExecuted
    function executeSettlement(bytes32 poolId, bool outcome) external {
        if (msg.sender != oracle) revert InvalidOracleData();

        SettlementInfo storage info = _settlements[poolId];
        if (info.pool == address(0)) revert PoolNotFound();
        if (info.status != SettlementStatus.Pending) revert SettlementAlreadyScheduled();
        if (block.timestamp < info.deadline) revert SettlementNotReady();

        info.status = SettlementStatus.Executed;

        IPredictionPool(info.pool).settle(outcome);

        emit SettlementExecuted(poolId, outcome);
    }

    /// @notice Gets the settlement status for a pool
    /// @param poolId Pool identifier
    /// @return SettlementStatus enum
    function getSettlementStatus(bytes32 poolId) external view returns (SettlementStatus) {
        if (_settlements[poolId].pool == address(0)) return SettlementStatus.Pending;
        return _settlements[poolId].status;
    }
}
