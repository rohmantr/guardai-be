# Task-003: RiskRegistry Contract

**Prioritas:** P0
**Dependencies:** —
**Module:** contracts/src/core/

---

## Objective

Buat kontrak `RiskRegistry.sol` yang menyimpan skor risiko per token secara immutable — hanya bisa diisi satu kali per token oleh agent.

## Specification

Lihat `docs/specifications/smart-contract-api.md` → RiskRegistry section.

### Interface

```solidity
function recordAssessment(address tokenAddress, uint256 probability, bytes32 assessmentId) external onlyAgent;
function getAssessment(address tokenAddress) external view returns (RiskAssessment memory);
function assessmentExists(address tokenAddress) external view returns (bool);
```

### State

```solidity
struct RiskAssessment {
  uint256 probability;  // scaled: 7500 = 0.75
  bytes32 assessmentId;
  uint256 timestamp;
}
```

### Design Notes

- **Immutability:** Setelah di-record untuk satu token, TIDAK bisa diubah
- **Probability scaling:** Simpan sebagai uint256 (0-10000) untuk menghindari float di Solidity
- **onlyAgent modifier:** Hanya address agent yang diset owner yang bisa record

### Files to Create

| File | Path |
|------|------|
| Contract | `contracts/src/core/RiskRegistry.sol` |
| Interface | `contracts/src/interfaces/IRiskRegistry.sol` |
| Unit test | `contracts/test/RiskRegistry.t.sol` |

### Acceptance Criteria

- [ ] `recordAssessment` stores assessment for token address
- [ ] Second record for same token reverts (`AssessmentAlreadyExists`)
- [ ] `getAssessment` returns correct data
- [ ] `assessmentExists` returns true/false correctly
- [ ] Only agent address can record
- [ ] Forge build + test passes
