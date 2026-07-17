// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/access/Ownable2Step.sol";
import {IOracleAdapter} from "../interfaces/IOracleAdapter.sol";

/// @title OracleAdapter
/// @notice Single entry point for triggering PredictionPool settlement via liquidity-pull events
/// @dev Only owner can submit resolution data (MVP). `proof` reserved for future oracle verification.
/// @custom:security Ownable2Step, one-time resolution per pool
contract OracleAdapter is IOracleAdapter, Ownable2Step {
    mapping(bytes32 => ResolutionData) private _resolutions;

    address public oracle;

    constructor() Ownable(msg.sender) {}

    /// @notice Records a liquidity-pull resolution for a pool. One-time per pool.
    /// @param poolId Pool identifier
    /// @param tokenAddress Token address being evaluated (emitted in event)
    /// @param proof Oracle proof data (ignored in MVP)
    /// @custom:security Reverts if pool already resolved
    /// @custom:emits LiquidityPullReported
    function reportLiquidityPull(bytes32 poolId, address tokenAddress, bytes calldata proof) external onlyOwner {
        if (_resolutions[poolId].timestamp != 0) revert AlreadyResolved();

        _resolutions[poolId] = ResolutionData({
            liquidityPulled: true,
            timestamp: block.timestamp,
            txHash: keccak256(abi.encode(poolId, tokenAddress, block.timestamp))
        });

        emit LiquidityPullReported(poolId, tokenAddress, block.timestamp);
    }

    /// @notice Check if a pool has been resolved
    /// @param poolId Pool identifier
    /// @return true if resolution data exists for this pool
    function isResolved(bytes32 poolId) external view returns (bool) {
        return _resolutions[poolId].timestamp != 0;
    }

    /// @notice Get resolution data for a pool
    /// @param poolId Pool identifier
    /// @return ResolutionData struct (zeroed if unresolved)
    function getResolutionData(bytes32 poolId) external view returns (ResolutionData memory) {
        return _resolutions[poolId];
    }

    /// @notice Updates the trusted oracle address (for future verification)
    /// @param _oracle New oracle address
    /// @custom:emits OracleUpdated
    function setOracle(address _oracle) external onlyOwner {
        emit OracleUpdated(oracle, _oracle);
        oracle = _oracle;
    }
}
