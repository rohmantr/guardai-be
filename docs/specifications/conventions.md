# Rug Radar — Project Conventions

**Versi:** 1.0
**Tanggal:** 13 Juli 2026

---

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Smart Contract | PascalCase | `PredictionPool`, `OracleAdapter` |
| Solidity Functions | camelCase | `buyPosition`, `getPoolInfo` |
| Solidity Variables | camelCase | `poolId`, `yesPoolAmount` |
| Solidity Internal | `s_` prefix | `s_status`, `s_deadline` |
| Solidity Constants | UPPER_SNAKE_CASE | `MAX_POOL_DURATION` |
| Solidity Immutable | `i_` prefix | `i_oracleAdapter` |
| Events | PascalCase (past tense) | `PoolCreated`, `PositionPurchased` |
| Custom Errors | PascalCase | `PoolNotActive`, `InsufficientPayment` |
| Enums | PascalCase | `Side`, `PoolStatus` |
| Typescript | PascalCase (types), camelCase (vars) | `TokenService`, `getToken()` |
| Database Tables | snake_case, plural | `prediction_pools`, `risk_assessments` |
| Database Columns | snake_case | `has_unlimited_mint`, `pool_id` |
| API Endpoints | kebab-case, plural | `/api/v1/tokens`, `/api/v1/pools` |
| JSON Fields | snake_case | `risk_factors`, `user_address` |
| Environment Vars | UPPER_SNAKE_CASE | `DATABASE_URL`, `LLM_API_KEY` |
| Git Branches | kebab-case | `feat/token-detector`, `fix/settlement-bug` |
| Commit Messages | Conventional Commits | `feat: add token detection worker` |

## Folder Conventions

```
contracts/
├── core/           # Kontrak utama bisnis logic
├── interfaces/     # Interface / abstract contracts
├── libraries/      # Library contracts
├── oracle/         # Oracle-related contracts
├── settlement/     # Settlement contracts
├── mocks/          # Mock contracts untuk testing
├── script/         # Deployment scripts
└── test/           # Unit, fuzz, invariant tests

src/                # Backend (NestJS)
├── modules/        # Per-module: controller, service, repository
├── common/         # Shared: middleware, errors, utils
└── workers/        # Background workers

docs/
├── architecture/   # Architecture decisions
├── business/       # BRD, PRD
├── decisions/      # ADR files
├── prompts/        # AI prompt docs
├── specifications/ # Technical specs
└── uml/            # UML diagrams
```

## File Naming

| File Type | Convention | Example |
|-----------|-----------|---------|
| Solidity contract | PascalCase.sol | `PredictionPool.sol` |
| Solidity test | PascalCase.t.sol | `PredictionPool.t.sol` |
| Solidity script | PascalCase.s.sol | `DeployPredictionPool.s.sol` |
| Typescript module | kebab-case.ts | `token.service.ts` |
| Typescript test | kebab-case.spec.ts | `token.service.spec.ts` |
| Migration | YYYYMMDDHHMMSS-description.ts | `20260713000001-create-tokens.ts` |
| Documentation | kebab-case.md | `smart-contract-api.md` |
| ADR | ADR-NNN-name.md | `ADR-001-foundry.md` |

## Commit Message Conventions

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

### Types

| Type | Usage |
|------|-------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting (fmt, lint) |
| `refactor` | Code restructuring |
| `test` | Adding/updating tests |
| `chore` | Build, CI, dependencies |
| `perf` | Performance improvement |
| `security` | Security fix |

### Scopes

| Scope | Area |
|-------|------|
| `contracts` | Solidity contracts |
| `backend` | NestJS backend |
| `agent` | AI agent |
| `docs` | Documentation |
| `ci` | CI/CD |

### Examples

```
feat(contracts): add PredictionPool contract

fix(backend): handle LLM timeout gracefully

docs: add smart contract API specification
```

## Branch Naming

```
<type>/<short-description>
```

| Prefix | Purpose |
|--------|---------|
| `feat/` | New feature |
| `fix/` | Bug fix |
| `docs/` | Documentation |
| `refactor/` | Code restructuring |
| `test/` | Testing |
| `chore/` | Maintenance |

**Examples:** `feat/token-detector`, `fix/settlement-revert`, `docs/smart-contract-api`

## Code Review Checklist

1. **Functionality:** Does it satisfy the requirements?
2. **Security:** Any reentrancy, access control, or injection risks?
3. **Testing:** Are there unit/fuzz/invariant tests? Do they pass?
4. **Gas:** Any unnecessary storage writes or loops?
5. **Naming:** Does it follow project conventions?
6. **Errors:** Are custom errors used (not require strings)?
7. **Events:** Does every state change emit an event?
8. **NatSpec:** Are public/external functions documented?
9. **No TODOs:** No placeholder code or commented-out code.
10. **fmt:** Is `forge fmt` or `prettier` applied?

## Documentation Standards

1. **File header:** Setiap doc file dimulai dengan title, version, date
2. **Mermaid diagrams:** Untuk state machines, sequences, architectures
3. **Tables:** Untuk data terstruktur (parameter, config, errors)
4. **Code blocks:** Dengan language tag (`solidity`, `typescript`, `json`, `yaml`)
5. **Cross-references:** Link ke file terkait (relative markdown links)
6. **Frontmatter:** YAML frontmatter untuk metadata ketika diperlukan
7. **No duplicated content:** Referensi, bukan copy-paste
