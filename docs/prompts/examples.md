# Rug Radar — Example Dataset

**Versi:** 1.0.0
**Tanggal:** 13 Juli 2026

---

## Example 1: Safe Token

**Input:**

```json
{
  "address": "0x1234567890abcdef1234567890abcdef12345678",
  "chain": "Base",
  "deployer": "0x9876543210fedcba9876543210fedcba98765432",
  "deployedAt": "2026-07-13T08:30:00Z",
  "hasUnlimitedMint": false,
  "hasBlacklist": false,
  "hasTax": false,
  "liquidityLocked": true,
  "topHolderConcentration": 0.12,
  "liquidityUsd": 500000
}
```

**Expected AI Response:**

```json
{
  "probability": 0.05,
  "reasoning": "Liquidity is locked, no dangerous functions detected, holder distribution is healthy (top 10 at 12%).",
  "confidence": 0.95,
  "riskFactors": []
}
```

---

## Example 2: Suspicious Token (High Risk)

**Input:**

```json
{
  "address": "0xdead00000000000000000000000000000000beef",
  "chain": "Base",
  "deployer": "0xabc123def456abc123def456abc123def456abc1",
  "deployedAt": "2026-07-13T06:15:00Z",
  "hasUnlimitedMint": true,
  "hasBlacklist": true,
  "hasTax": true,
  "liquidityLocked": false,
  "topHolderConcentration": 0.89,
  "liquidityUsd": 2500
}
```

**Expected AI Response:**

```json
{
  "probability": 0.94,
  "reasoning": "Unlimited mint, blacklist, and tax functions detected. Liquidity is not locked and top 10 holders control 89% of supply.",
  "confidence": 0.92,
  "riskFactors": ["unlimited_mint", "blacklist_function", "transfer_tax", "liquidity_not_locked", "high_holder_concentration"]
}
```

---

## Example 3: Confirmed Rug-Pull (Post-Mortem)

**Input:**

```json
{
  "address": "0xrug00000000000000000000000000000000000001",
  "chain": "Base",
  "deployer": "0xbadbadbadbadbadbadbadbadbadbadbadbadbadb",
  "deployedAt": "2026-07-12T14:00:00Z",
  "hasUnlimitedMint": true,
  "hasBlacklist": false,
  "hasTax": false,
  "liquidityLocked": false,
  "topHolderConcentration": 0.97,
  "liquidityUsd": 85000
}
```

**Expected AI Response:**

```json
{
  "probability": 0.98,
  "reasoning": "Unlimited mint function, liquidity not locked, and deployer holds 97% of supply. Classic rug-pull setup.",
  "confidence": 0.91,
  "riskFactors": ["unlimited_mint", "liquidity_not_locked", "deployer_holds_large"]
}
```

**Actual Outcome:** Liquidity pulled 6 hours after deploy. All LP drained.

---

## Example 4: Intermediate (Proxy Contract)

**Input:**

```json
{
  "address": "0xproxy00000000000000000000000000000000abcd",
  "chain": "Base",
  "deployer": "0xnormaldeployer123456789012345678901234567890",
  "deployedAt": "2026-07-13T10:00:00Z",
  "hasUnlimitedMint": false,
  "hasBlacklist": false,
  "hasTax": false,
  "liquidityLocked": true,
  "topHolderConcentration": 0.45,
  "liquidityUsd": 120000
}
```

**Expected AI Response:**

```json
{
  "probability": 0.35,
  "reasoning": "Uses proxy pattern (upgradable contract). No dangerous functions detected, but proxy allows future logic changes. Liquidity is locked.",
  "confidence": 0.78,
  "riskFactors": ["proxy_contract"]
}
```

---

## Example 5: Minimal Data

**Input:**

```json
{
  "address": "0xnew00000000000000000000000000000000000001",
  "chain": "Base",
  "deployer": "0xunknown0000000000000000000000000000000000",
  "deployedAt": "2026-07-13T11:00:00Z"
}
```

**Expected AI Response:**

```json
{
  "probability": 0.50,
  "reasoning": "Only basic contract data available (address, deployer, timestamp). Cannot assess contract functions, liquidity, or holder distribution.",
  "confidence": 0.15,
  "riskFactors": ["insufficient_data"]
}
```
