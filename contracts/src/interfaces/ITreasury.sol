// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface ITreasury {
    function registerPool(address pool, bytes32 poolId) external;
    function deposit() external payable;
    function payout(address winner, uint256 amount) external;
    function withdrawFees(address to, uint256 amount) external;
    function setFeeBps(uint256 newFeeBps) external;
    function getBalance(bytes32 poolId) external view returns (uint256);

    event PoolRegistered(address indexed pool, bytes32 indexed poolId);
    event Deposited(bytes32 indexed poolId, address indexed pool, uint256 amount);
    event PayoutSent(bytes32 indexed poolId, address indexed winner, uint256 amount);
    event FeesWithdrawn(address indexed to, uint256 amount);
    event FeeUpdated(uint256 newFeeBps);

    error InsufficientBalance();
    error TransferFailed();
    error UnauthorizedPool();
    error FeeTooHigh();
    error ZeroAddress();
    error PoolAlreadyRegistered();
}
