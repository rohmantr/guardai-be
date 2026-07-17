// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/access/Ownable2Step.sol";
import {ReentrancyGuard} from "@openzeppelin/utils/ReentrancyGuard.sol";
import {ITreasury} from "../interfaces/ITreasury.sol";

contract Treasury is ITreasury, Ownable2Step, ReentrancyGuard {
    mapping(bytes32 => uint256) private _poolBalances;
    mapping(address => bool) public registeredPools;
    mapping(address => bytes32) public poolIdOf;
    uint256 public feeBps;
    uint256 private _accumulatedFees;

    uint256 public constant MAX_FEE_BPS = 1000;

    modifier onlyRegisteredPool() {
        if (!registeredPools[msg.sender]) revert UnauthorizedPool();
        _;
    }

    constructor() Ownable(msg.sender) {}

    function registerPool(address pool, bytes32 _poolId) external onlyOwner {
        if (pool == address(0)) revert ZeroAddress();
        if (registeredPools[pool]) revert PoolAlreadyRegistered();

        registeredPools[pool] = true;
        poolIdOf[pool] = _poolId;

        emit PoolRegistered(pool, _poolId);
    }

    function setFeeBps(uint256 newFeeBps) external onlyOwner {
        if (newFeeBps > MAX_FEE_BPS) revert FeeTooHigh();
        feeBps = newFeeBps;
        emit FeeUpdated(newFeeBps);
    }

    function deposit() external payable onlyRegisteredPool {
        bytes32 _poolId = poolIdOf[msg.sender];

        uint256 fee = (msg.value * feeBps) / 10000;
        _accumulatedFees += fee;
        _poolBalances[_poolId] += msg.value - fee;

        emit Deposited(_poolId, msg.sender, msg.value - fee);
    }

    function payout(address winner, uint256 amount) external nonReentrant onlyRegisteredPool {
        if (winner == address(0)) revert ZeroAddress();

        bytes32 _poolId = poolIdOf[msg.sender];

        if (_poolBalances[_poolId] < amount) revert InsufficientBalance();

        // CEI: state update before external call
        _poolBalances[_poolId] -= amount;

        (bool sent,) = payable(winner).call{value: amount}("");
        if (!sent) revert TransferFailed();

        emit PayoutSent(_poolId, winner, amount);
    }

    function withdrawFees(address to, uint256 amount) external nonReentrant onlyOwner {
        if (to == address(0)) revert ZeroAddress();

        if (_accumulatedFees < amount) revert InsufficientBalance();

        // CEI: state update before external call
        _accumulatedFees -= amount;

        (bool sent,) = payable(to).call{value: amount}("");
        if (!sent) revert TransferFailed();

        emit FeesWithdrawn(to, amount);
    }

    function getBalance(bytes32 _poolId) external view returns (uint256) {
        return _poolBalances[_poolId];
    }
}
