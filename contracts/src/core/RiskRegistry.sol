// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/access/Ownable2Step.sol";
import {IRiskRegistry} from "../interfaces/IRiskRegistry.sol";

/// @title RiskRegistry
/// @notice Stores immutable risk scores per token — one assessment per token, set by an authorized agent
/// @dev Only the agent address can record. Once recorded for a token, it cannot be overwritten.
///      Probability is stored as uint256 (0–10000) to avoid floating point in Solidity.
/// @custom:security Ownable2Step for ownership transfer security
contract RiskRegistry is IRiskRegistry, Ownable2Step {
    mapping(address => RiskAssessment) private s_assessments;

    address public agent;

    modifier onlyAgent() {
        if (msg.sender != agent) revert NotAuthorizedAgent();
        _;
    }

    constructor() Ownable(msg.sender) {}

    /// @notice Set the authorized agent address
    /// @param _agent Address allowed to record assessments
    function setAgent(address _agent) external onlyOwner {
        agent = _agent;
    }

    /// @notice Record a risk assessment for a token. One-time per token, immutable after write.
    /// @param tokenAddress The token address to assess
    /// @param probability Risk score scaled 0–10000
    /// @param assessmentId Unique assessment identifier
    /// @custom:security immutable — no update or delete path
    /// @custom:emits AssessmentRecorded
    function recordAssessment(address tokenAddress, uint256 probability, bytes32 assessmentId) external onlyAgent {
        if (probability > 10000) revert InvalidProbability();
        if (s_assessments[tokenAddress].timestamp != 0) revert AssessmentAlreadyExists();

        s_assessments[tokenAddress] =
            RiskAssessment({probability: probability, assessmentId: assessmentId, timestamp: block.timestamp});

        emit AssessmentRecorded(tokenAddress, probability, assessmentId);
    }

    /// @notice Get the risk assessment for a token
    /// @param tokenAddress The token address
    /// @return RiskAssessment struct (probability, assessmentId, timestamp)
    /// @dev Returns zeroed struct if token has not been assessed
    function getAssessment(address tokenAddress) external view returns (RiskAssessment memory) {
        return s_assessments[tokenAddress];
    }

    /// @notice Check if a token has been assessed
    /// @param tokenAddress The token address
    /// @return true if an assessment exists for this token
    /// @dev Uses timestamp != 0 as existence check (valid since timestamp > 0 after record)
    function assessmentExists(address tokenAddress) external view returns (bool) {
        return s_assessments[tokenAddress].timestamp != 0;
    }
}
