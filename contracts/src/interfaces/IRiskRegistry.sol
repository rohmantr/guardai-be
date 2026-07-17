// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title Risk Registry Interface
/// @notice Interface for immutable, one-time risk assessment storage per token
interface IRiskRegistry {
    /// @notice Risk assessment data for a token
    /// @param probability Risk score scaled 0–10000 (7500 = 0.75)
    /// @param assessmentId Unique assessment identifier from the AI agent
    /// @param timestamp Block timestamp when assessment was recorded
    struct RiskAssessment {
        uint256 probability;
        bytes32 assessmentId;
        uint256 timestamp;
    }

    /// @notice Record a risk assessment for a token. One-time per token.
    /// @param tokenAddress The token address to assess
    /// @param probability Risk score scaled 0–10000
    /// @param assessmentId Unique assessment identifier
    /// @custom:emits AssessmentRecorded
    function recordAssessment(address tokenAddress, uint256 probability, bytes32 assessmentId) external;

    /// @notice Get the risk assessment for a token
    /// @param tokenAddress The token address
    /// @return RiskAssessment struct (probability, assessmentId, timestamp)
    function getAssessment(address tokenAddress) external view returns (RiskAssessment memory);

    /// @notice Check if a token has been assessed
    /// @param tokenAddress The token address
    /// @return true if an assessment exists for this token
    function assessmentExists(address tokenAddress) external view returns (bool);

    event AssessmentRecorded(address indexed token, uint256 probability, bytes32 indexed assessmentId);

    error AssessmentAlreadyExists();

    error InvalidProbability();

    error NotAuthorizedAgent();
}
