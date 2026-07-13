// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/access/Ownable2Step.sol";
import {ReentrancyGuard} from "@openzeppelin/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/utils/Pausable.sol";
import {IPredictionPool} from "../interfaces/IPredictionPool.sol";

/// @title PredictionPool
/// @notice Manages binary prediction positions (YES/NO) for a single token
/// @dev Only OracleAdapter can trigger settlement. Implements CEI, ReentrancyGuard, Pausable.
/// @custom:security ReentrancyGuard, Pausable, Checks-Effects-Interactions
contract PredictionPool is IPredictionPool, Ownable2Step, ReentrancyGuard, Pausable {
    // ──────────────────────────────────────────────
    //  State
    // ──────────────────────────────────────────────

    bytes32 public poolId;
    address public tokenAddress;
    uint256 public yesPool;
    uint256 public noPool;
    PoolStatus public status;
    uint256 public deadline;
    Side public winningSide;
    address public oracleAdapter;

    mapping(address => UserPosition) private _positions;

    // ──────────────────────────────────────────────
    //  Errors
    // ──────────────────────────────────────────────

    error PoolNotActive();
    error PoolNotResolved();
    error PoolAlreadyExpired();
    error AlreadyResolved();
    error NotOracleAdapter();
    error InsufficientPayment();
    error PositionTooSmall();
    error NothingToClaim();
    error AlreadyClaimed();
    error DeadlineNotReached();
    error TransferFailed();

    // ──────────────────────────────────────────────
    //  Modifiers
    // ──────────────────────────────────────────────

    modifier onlyWhenActive() {
        if (status != PoolStatus.Active) revert PoolNotActive();
        _;
    }

    modifier onlyWhenResolved() {
        if (status != PoolStatus.Resolved) revert PoolNotResolved();
        _;
    }

    modifier onlyOracle() {
        if (msg.sender != oracleAdapter) revert NotOracleAdapter();
        _;
    }

    modifier onlyBeforeDeadline() {
        if (block.timestamp >= deadline) revert PoolAlreadyExpired();
        _;
    }

    // ──────────────────────────────────────────────
    //  Constructor
    // ──────────────────────────────────────────────

    /// @notice Deploys a new prediction pool
    /// @param _poolId Unique identifier for this pool
    /// @param _tokenAddress Token being assessed
    /// @param _oracleAdapter Address authorized to trigger settlement
    /// @param _deadline Timestamp after which the pool expires
    constructor(bytes32 _poolId, address _tokenAddress, address _oracleAdapter, uint256 _deadline) Ownable(msg.sender) {
        poolId = _poolId;
        tokenAddress = _tokenAddress;
        oracleAdapter = _oracleAdapter;
        deadline = _deadline;
        status = PoolStatus.Active;

        emit PoolCreated(_poolId, _tokenAddress, _deadline);
    }

    // ──────────────────────────────────────────────
    //  Core
    // ──────────────────────────────────────────────

    /// @notice Buys a position (YES or NO) in the prediction pool
    /// @param side YES (0) or NO (1)
    /// @param amount Amount of wei to wager
    /// @dev Reverts if pool is not active, expired, or amount is zero
    /// @custom:emits PositionPurchased
    function buyPosition(Side side, uint256 amount)
        external
        payable
        whenNotPaused
        onlyWhenActive
        onlyBeforeDeadline
        nonReentrant
    {
        if (amount == 0) revert PositionTooSmall();
        if (msg.value < amount) revert InsufficientPayment();

        UserPosition storage pos = _positions[msg.sender];

        if (side == Side.YES) {
            yesPool += amount;
            pos.yesAmount += amount;
        } else {
            noPool += amount;
            pos.noAmount += amount;
        }

        emit PositionPurchased(poolId, msg.sender, side, amount);
    }

    /// @notice Settles the pool with the winning outcome
    /// @param liquidityPulled true = YES wins, false = NO wins
    /// @dev Only callable by OracleAdapter
    /// @custom:security CEI: state update before external call (no external call here)
    /// @custom:emits PoolResolved
    function settle(bool liquidityPulled) external onlyOracle onlyWhenActive {
        if (block.timestamp >= deadline) revert PoolAlreadyExpired();

        status = PoolStatus.Resolved;
        winningSide = liquidityPulled ? Side.YES : Side.NO;

        emit PoolResolved(poolId, winningSide, yesPool, noPool);
    }

    /// @notice Claims payout after settlement
    /// @param user Address to claim for
    /// @return payout Amount of wei sent to the user
    /// @custom:security CEI: state update before ETH transfer, ReentrancyGuard
    /// @custom:emits ClaimExecuted
    function claim(address user) external nonReentrant onlyWhenResolved returns (uint256 payout) {
        UserPosition storage pos = _positions[user];
        if (pos.claimed) revert AlreadyClaimed();

        uint256 userAmount;
        uint256 totalWinningPool;

        if (winningSide == Side.YES) {
            userAmount = pos.yesAmount;
            totalWinningPool = yesPool;
        } else {
            userAmount = pos.noAmount;
            totalWinningPool = noPool;
        }

        if (userAmount == 0) revert NothingToClaim();

        uint256 totalPool = yesPool + noPool;

        // CEI: state update BEFORE external call
        pos.claimed = true;

        // Proportional payout: (userAmount / totalWinningPool) * totalPool
        payout = (userAmount * totalPool) / totalWinningPool;

        (bool sent,) = payable(user).call{value: payout}("");
        if (!sent) revert TransferFailed();

        emit ClaimExecuted(poolId, user, payout);
    }

    /// @notice Expires the pool after deadline if not settled
    /// @dev Anyone can call after deadline passes
    /// @custom:emits PoolExpired
    function expire() external {
        if (block.timestamp < deadline) revert DeadlineNotReached();
        if (status != PoolStatus.Active) revert PoolNotActive();

        status = PoolStatus.Expired;
        emit PoolExpired(poolId);
    }

    // ──────────────────────────────────────────────
    //  Getters
    // ──────────────────────────────────────────────

    /// @notice Returns full pool info
    function getPoolInfo() external view returns (PoolInfo memory) {
        return PoolInfo({
            poolId: poolId,
            tokenAddress: tokenAddress,
            yesPool: yesPool,
            noPool: noPool,
            status: status,
            deadline: deadline,
            winningSide: winningSide
        });
    }

    /// @notice Returns a user's position
    function getPosition(address user) external view returns (UserPosition memory) {
        return _positions[user];
    }

    /// @notice Returns true if pool is active
    function isActive() external view returns (bool) {
        return status == PoolStatus.Active;
    }

    /// @notice Returns true if pool is resolved
    function isResolved() external view returns (bool) {
        return status == PoolStatus.Resolved;
    }

    // ──────────────────────────────────────────────
    //  Admin (owner only)
    // ──────────────────────────────────────────────

    /// @notice Pauses the pool (emergency stop)
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the pool
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Updates the OracleAdapter address
    /// @param _oracleAdapter New OracleAdapter address
    /// @custom:emits OracleAdapterUpdated
    function setOracleAdapter(address _oracleAdapter) external onlyOwner {
        emit OracleAdapterUpdated(oracleAdapter, _oracleAdapter);
        oracleAdapter = _oracleAdapter;
    }
}
