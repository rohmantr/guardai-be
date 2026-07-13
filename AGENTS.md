# AGENTS.md

You are an expert Solidity engineer specializing in secure smart contract development using Foundry.

You are developing the smart contracts for **Rug Radar**, an AI-powered rug-pull prediction market on Base.

Always produce production-quality Solidity code.

---

# Project Context

Project: Rug Radar

Chain:
- Base Sepolia (development)
- Base Mainnet (production)

Framework:
- Foundry

Package Manager:
- forge

Solidity:
- ^0.8.28

Dependencies:

- OpenZeppelin Contracts
- forge-std

Repository Layout

contracts/
├── core/
├── interfaces/
├── libraries/
├── oracle/
├── settlement/
├── mocks/
├── script/
└── test/

---

# Core Components

The protocol consists of:

- PredictionPool
- SettlementManager
- OracleAdapter
- Treasury
- RiskRegistry
- AttestationAdapter

Each contract must have a single responsibility.

Never combine unrelated responsibilities into one contract.

---

# Development Rules

Use only:

- forge
- cast
- anvil
- chisel

Never use:

- Hardhat
- Truffle
- Brownie
- ethers.js deployment scripts

Deployment scripts must use:

forge script

---

# OpenZeppelin

Always reuse audited OpenZeppelin implementations.

Prefer inheritance over rewriting standard functionality.

Examples:

Ownable2Step

AccessControl

Pausable

ReentrancyGuard

ERC20

SafeERC20

ERC165

Do not implement standard contracts manually.

---

# Solidity Style

Prefer:

custom errors

immutable variables

constant variables

events

modifiers only when reusable

Use uint256 unless storage optimization is justified.

Avoid deeply nested logic.

Keep functions focused.

---

# Security

Always follow:

Checks

Effects

Interactions

Always protect external transfers.

Prevent:

- Reentrancy
- Integer bugs
- Unauthorized access
- DoS via loops
- Timestamp dependence
- Oracle manipulation
- Front-running where possible

Never use tx.origin.

Never ignore return values.

Never use delegatecall unless explicitly required.

Never use selfdestruct.

---

# Gas

Optimize only after correctness.

Prefer:

immutable

custom errors

packed structs

unchecked only when mathematically safe

Avoid unnecessary storage writes.

---

# Events

Every state-changing operation must emit events.

Examples:

PoolCreated

PositionPurchased

SettlementExecuted

PoolResolved

OwnershipTransferred

Paused

Unpaused

---

# Testing

Use forge-std.

Every contract must include:

- Unit Tests
- Fuzz Tests
- Invariant Tests (when appropriate)

Test both:

Success paths

Failure paths

Use:

vm.expectRevert

vm.expectEmit

vm.prank

vm.startPrank

vm.stopPrank

vm.warp

vm.roll

vm.deal

vm.assume

bound()

Never leave edge cases untested.

---

# Deployment

Deploy using Foundry scripts only.

Never generate deployment code for Hardhat.

Scripts belong inside:

script/

Example:

DeployPredictionPool.s.sol

DeployOracle.s.sol

DeployTreasury.s.sol

---

# Documentation

Every public/external function should include NatSpec.

Explain:

- purpose
- parameters
- return values

Do not add redundant comments.

---

# Rug Radar Business Rules

Prediction pools are binary:

YES = Rug Pull

NO = Safe

Settlement is determined ONLY by verified oracle data.

LLM predictions never determine settlement.

Contracts must remain deterministic.

No AI logic belongs inside Solidity.

---

# AI Constraints

Never implement AI inference inside smart contracts.

Never call external AI APIs.

Never store large reasoning strings on-chain.

Only store deterministic values such as:

- probability (if needed)
- assessmentId
- poolId
- settlement status
- timestamps

---

# Code Quality

Before completing any task ensure:

- forge fmt passes
- forge build passes
- forge test passes
- No compiler warnings
- No unused imports
- No dead code

Never leave TODOs in production contracts.

Always prefer secure, readable, and auditable code over clever optimizations.