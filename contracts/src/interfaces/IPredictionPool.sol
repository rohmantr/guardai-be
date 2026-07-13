// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IPredictionPool {
    enum Side {
        YES,
        NO
    }
    enum PoolStatus {
        Pending,
        Active,
        Resolved,
        Expired
    }

    struct PoolInfo {
        bytes32 poolId;
        address tokenAddress;
        uint256 yesPool;
        uint256 noPool;
        PoolStatus status;
        uint256 deadline;
        Side winningSide;
    }

    struct UserPosition {
        uint256 yesAmount;
        uint256 noAmount;
        bool claimed;
    }

    function buyPosition(Side side, uint256 amount) external payable;
    function settle(bool liquidityPulled) external;
    function claim(address user) external returns (uint256 payout);
    function expire() external;
    function getPoolInfo() external view returns (PoolInfo memory);
    function getPosition(address user) external view returns (UserPosition memory);
    function isActive() external view returns (bool);
    function isResolved() external view returns (bool);

    event PoolCreated(bytes32 indexed poolId, address indexed token, uint256 deadline);
    event PositionPurchased(bytes32 indexed poolId, address indexed user, Side side, uint256 amount);
    event PoolResolved(bytes32 indexed poolId, Side winningSide, uint256 totalYes, uint256 totalNo);
    event ClaimExecuted(bytes32 indexed poolId, address indexed user, uint256 payout);
    event PoolExpired(bytes32 indexed poolId);
    event OracleAdapterUpdated(address indexed oldAdapter, address indexed newAdapter);
}
