# Rug Radar — Output Schema

**Versi:** 1.0.0
**Tanggal:** 13 Juli 2026

---

## JSON Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["probability", "reasoning", "confidence", "riskFactors"],
  "properties": {
    "probability": {
      "type": "number",
      "minimum": 0.0,
      "maximum": 1.0,
      "description": "Probability that token is a rug-pull"
    },
    "reasoning": {
      "type": "string",
      "minLength": 1,
      "maxLength": 200,
      "description": "Brief explanation of the assessment"
    },
    "confidence": {
      "type": "number",
      "minimum": 0.0,
      "maximum": 1.0,
      "description": "Confidence in the assessment based on data completeness"
    },
    "riskFactors": {
      "type": "array",
      "minItems": 0,
      "maxItems": 5,
      "items": {
        "type": "string",
        "enum": [
          "unlimited_mint",
          "blacklist_function",
          "transfer_tax",
          "liquidity_not_locked",
          "liquidity_low",
          "high_holder_concentration",
          "deployer_holds_large",
          "honeypot_detected",
          "insufficient_data",
          "no_verified_source",
          "proxy_contract",
          "ownership_renounced"
        ]
      },
      "description": "Specific risk factors identified"
    }
  }
}
```

## Field Documentation

### `probability`

| Aspek | Detail |
|-------|--------|
| Tipe | number (float) |
| Range | 0.0 — 1.0 |
| Required | Yes |
| Contoh | 0.0 (safe), 0.5 (neutral), 1.0 (confirmed rug) |

Interpretasi:
| Range | Arti |
|-------|------|
| 0.0 - 0.2 | Kemungkinan rug sangat rendah |
| 0.2 - 0.4 | Kemungkinan rug rendah |
| 0.4 - 0.6 | Netral / tidak cukup data |
| 0.6 - 0.8 | Kemungkinan rug tinggi |
| 0.8 - 1.0 | Sangat mungkin rug-pull |

### `reasoning`

| Aspek | Detail |
|-------|--------|
| Tipe | string |
| Length | 1 - 200 characters |
| Required | Yes |
| Contoh | `"Unlimited mint function and no liquidity lock. Top holder has 72% supply."` |

### `confidence`

| Aspek | Detail |
|-------|--------|
| Tipe | number (float) |
| Range | 0.0 — 1.0 |
| Required | Yes |
| Contoh | 0.95 (full data), 0.30 (minimal data) |

Interpretasi:
| Range | Arti |
|-------|------|
| 0.0 - 0.3 | Data minimal, hasil tidak reliabel |
| 0.3 - 0.6 | Data parsial, gunakan dengan hati-hati |
| 0.6 - 0.8 | Sebagian besar data tersedia |
| 0.8 - 1.0 | Data lengkap |

### `riskFactors`

| Aspek | Detail |
|-------|--------|
| Tipe | array of strings |
| Min items | 0 |
| Max items | 5 |
| Required | Yes |
| Contoh | `["unlimited_mint", "liquidity_not_locked"]` |

## Validation Rules

1. `probability` di luar [0.0, 1.0] → **REJECT**, retry with stricter prompt
2. `confidence` di luar [0.0, 1.0] → **REJECT**, retry with stricter prompt
3. `reasoning` > 200 chars → **TRUNCATE** ke 200 chars
4. `riskFactors` item tidak ada di enum → **FILTER OUT**, log warning
5. JSON tidak valid (parse error) → **RETRY** max 2x, fallback probability = 0.5

## Valid Examples

```json
// Safe token
{"probability": 0.05, "reasoning": "Liquidity is locked. No mint function. Holder distribution is healthy.", "confidence": 0.92, "riskFactors": []}

// Suspicious token
{"probability": 0.82, "reasoning": "Ownership not renounced. Blacklist function exists. Top holder has 65%.", "confidence": 0.88, "riskFactors": ["blacklist_function", "high_holder_concentration", "ownership_renounced"]}

// Insufficient data
{"probability": 0.50, "reasoning": "Could only read basic contract data. Liquidity and holders unknown.", "confidence": 0.15, "riskFactors": ["insufficient_data"]}
```

## Invalid Examples (harus ditolak / di-retry)

```json
// probability out of range
{"probability": 2.5, ...}

// missing required field
{"probability": 0.5, "reasoning": "test"}  // missing confidence, riskFactors

// reasoning too long
{"probability": 0.5, "reasoning": "a".repeat(201), "confidence": 0.5, "riskFactors": []}

// invalid riskFactor
{"probability": 0.5, "reasoning": "test", "confidence": 0.5, "riskFactors": ["unknown_factor"]}
```

## Malformed Response Handling

| Skenario | Action |
|----------|--------|
| JSON parse error | Retry 2x dengan prompt "Respond with ONLY valid JSON" |
| Missing required field | Retry 1x dengan list required fields di prompt |
| Field type mismatch | Reject, log error, fallback probability 0.5 |
| Extra unexpected fields | Strip extra fields, proceed with valid fields |
| Empty response | Retry 2x, fallback probability 0.5, confidence 0.1 |
