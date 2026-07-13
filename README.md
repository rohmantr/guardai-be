# Rug Radar

AI-powered rug-pull prediction market on **Base**.

## Structure

```
guardai-be/
├── contracts/        # Solidity smart contracts (Foundry)
│   ├── src/
│   │   ├── core/         # PredictionPool, Treasury
│   │   ├── interfaces/   # Interface contracts
│   │   ├── libraries/    # Library contracts
│   │   ├── oracle/       # OracleAdapter
│   │   ├── settlement/   # SettlementManager
│   │   └── mocks/        # Mock contracts (testing)
│   ├── script/           # forge deploy scripts
│   ├── test/             # forge tests
│   └── lib/              # forge dependencies
├── src/              # Backend (NestJS)
│   ├── modules/
│   │   ├── token/
│   │   ├── assessment/
│   │   ├── prediction/
│   │   ├── oracle/
│   │   └── attestation/
│   ├── common/
│   └── workers/
├── agent/            # AI Agent logic
├── docs/             # Documentation
│   ├── architecture/
│   ├── business/
│   ├── decisions/
│   ├── prompts/
│   ├── specifications/
│   └── uml/
├── scripts/          # Dev/deployment scripts
├── .env.example
└── docker-compose.yml
```

## Quick Start

```bash
# Prerequisites
# - Foundry (forge, cast, anvil)
# - Node.js 20+
# - PostgreSQL 16+

# Backend
bun install
cp .env.example .env
bun run dev

# Contracts
cd contracts
forge build
forge test
```

## Docs

All documentation in `docs/`. Start with `docs/architecture/architecture.md`.
