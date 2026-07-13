# Rug Radar — Error Codes

**Versi:** 1.0
**Tanggal:** 13 Juli 2026

---

## Error Code Format

```
RR_{CATEGORY}_{SPECIFIC_ERROR}
```

Format: `UPPERCASE_SNAKE_CASE`, diawali prefix `RR_` (Rug Radar).

## Application Errors (RR_APP_*)

| Code | HTTP | Description | Retry |
|------|------|-------------|-------|
| `RR_APP_INTERNAL_ERROR` | 500 | Unexpected server error | No |
| `RR_APP_SERVICE_UNAVAILABLE` | 503 | Dependency (DB, Redis) unavailable | Yes, backoff |
| `RR_APP_RATE_LIMITED` | 429 | Too many requests | Yes, after window |
| `RR_APP_NOT_FOUND` | 404 | Resource not found | No |
| `RR_APP_CONFLICT` | 409 | Resource already exists | No |

## Blockchain Errors (RR_CHAIN_*)

| Code | HTTP | Description | Retry |
|------|------|-------------|-------|
| `RR_CHAIN_RPC_ERROR` | 502 | RPC call failed | Yes, 3x |
| `RR_CHAIN_RPC_TIMEOUT` | 504 | RPC request timeout | Yes, 2x |
| `RR_CHAIN_CONTRACT_ERROR` | 422 | Contract call reverted | No |
| `RR_CHAIN_INVALID_ADDRESS` | 400 | Invalid contract address | No |
| `RR_CHAIN_INSUFFICIENT_FUNDS` | 422 | Insufficient balance for tx | No |
| `RR_CHAIN_TX_FAILED` | 422 | Transaction reverted on-chain | No |

## AI Processing Errors (RR_AI_*)

| Code | HTTP | Description | Retry |
|------|------|-------------|-------|
| `RR_AI_LLM_TIMEOUT` | 504 | LLM request timeout (>15s) | Yes, 2x |
| `RR_AI_LLM_ERROR` | 502 | LLM API returned error | Yes, 2x |
| `RR_AI_PARSE_ERROR` | 422 | Could not parse LLM response JSON | Yes, 2x |
| `RR_AI_SCHEMA_ERROR` | 422 | LLM output violates schema | Yes, 1x |
| `RR_AI_RATE_LIMITED` | 429 | LLM API rate limit hit | Yes, exponential |
| `RR_AI_INVALID_PROBABILITY` | 422 | Probability out of range [0.0, 1.0] | No |
| `RR_AI_INVALID_CONFIDENCE` | 422 | Confidence out of range [0.0, 1.0] | No |
| `RR_AI_EMPTY_RESPONSE` | 502 | Empty response from LLM | Yes, 2x |

## Database Errors (RR_DB_*)

| Code | HTTP | Description | Retry |
|------|------|-------------|-------|
| `RR_DB_CONNECTION_ERROR` | 503 | Database connection failed | Yes, 3x |
| `RR_DB_QUERY_ERROR` | 500 | Query execution failed | No |
| `RR_DB_UNIQUE_CONSTRAINT` | 409 | Unique constraint violation | No |
| `RR_DB_FOREIGN_KEY` | 409 | Foreign key violation | No |
| `RR_DB_MIGRATION_ERROR` | 500 | Migration state inconsistent | No |

## Validation Errors (RR_VALIDATION_*)

| Code | HTTP | Description | Retry |
|------|------|-------------|-------|
| `RR_VALIDATION_MISSING_FIELD` | 400 | Required field is missing | No |
| `RR_VALIDATION_INVALID_FORMAT` | 400 | Field format is invalid | No |
| `RR_VALIDATION_OUT_OF_RANGE` | 400 | Field value out of allowed range | No |
| `RR_VALIDATION_INVALID_ENUM` | 400 | Value not in allowed enum | No |
| `RR_VALIDATION_INPUT_TOO_LONG` | 400 | Input exceeds maximum length | No |
| `RR_VALIDATION_INVALID_ADDRESS` | 400 | Not a valid Ethereum address | No |

## Authentication Errors (RR_AUTH_*)

| Code | HTTP | Description | Retry |
|------|------|-------------|-------|
| `RR_AUTH_INVALID_KEY` | 401 | API key is invalid | No |
| `RR_AUTH_EXPIRED_KEY` | 401 | API key has expired | No |
| `RR_AUTH_UNAUTHORIZED` | 403 | Not authorized for this action | No |
| `RR_AUTH_SIGNATURE_INVALID` | 401 | EIP-4361 signature invalid | No |
| `RR_AUTH_RATE_LIMITED` | 429 | Auth rate limit exceeded | Yes, after window |

## HTTP Status Code Mapping

| HTTP | Meaning | Typical Cases |
|------|---------|---------------|
| 400 | Bad Request | Validation errors |
| 401 | Unauthorized | Invalid/expired API key |
| 403 | Forbidden | Valid key, insufficient permissions |
| 404 | Not Found | Resource doesn't exist |
| 409 | Conflict | Duplicate resource |
| 422 | Unprocessable | Business logic violation |
| 429 | Too Many Requests | Rate limit |
| 500 | Internal Server Error | Unexpected failure |
| 502 | Bad Gateway | Dependency (LLM, RPC) failed |
| 503 | Service Unavailable | Database/Redis down |
| 504 | Gateway Timeout | LLM/RPC timeout |

## Retry Recommendations

| Category | Max Retries | Backoff Strategy |
|----------|-------------|------------------|
| Network / RPC | 3 | Linear: 1s, 2s, 3s |
| LLM API | 2 | Linear: 2s, 5s |
| LLM Rate Limit | 3 | Exponential: 30s, 60s, 120s |
| Database Connection | 3 | Exponential: 1s, 3s, 10s |
| Validation errors | 0 | Don't retry — fix input |
| Auth errors | 0 | Don't retry — check credentials |

## Response Format

Semua error dikembalikan dalam format:

```json
{
  "success": false,
  "error": {
    "code": "RR_VALIDATION_MISSING_FIELD",
    "message": "Required field 'side' is missing",
    "details": {
      "field": "side",
      "expected": "YES | NO"
    }
  }
}
```
