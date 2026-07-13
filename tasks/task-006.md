# Task-006: AttestationAdapter Contract

**Prioritas:** P1
**Dependencies:** —
**Module:** contracts/src/core/

---

## Objective

Buat kontrak `AttestationAdapter.sol` yang mencatat hasil settlement ke EAS (Ethereum Attestation Service) untuk track record on-chain agent.

## Specification

Lihat `docs/specifications/smart-contract-api.md` → AttestationAdapter section.

### Interface

```solidity
function attestResult(bytes32 poolId, bool predictedOutcome, bool actualOutcome) external returns (bytes32 uid);
function getAttestation(bytes32 poolId) external view returns (Attestation memory);
```

### Design Notes

- **EAS integration:** Gunakan `IEAS` interface dari OpenZeppelin
- **Schema:** Attestation schema sesuai `docs/specifications/integrations.md`
- **One attestation per pool:** Setelah di-attest, tidak bisa diubah
- **MVP:** Bisa skip actual EAS call, cukup simpan attestation data di contract sendiri (EAS integration bisa dummy untuk demo)

### Files to Create

| File | Path |
|------|------|
| Contract | `contracts/src/core/AttestationAdapter.sol` |
| Interface | `contracts/src/interfaces/IAttestationAdapter.sol` |
| Mock EAS | `contracts/src/mocks/MockEAS.sol` |
| Unit test | `contracts/test/AttestationAdapter.t.sol` |

### Acceptance Criteria

- [ ] `attestResult` creates attestation record
- [ ] Same pool cannot be attested twice
- [ ] `getAttestation` returns correct data
- [ ] Mock EAS works for testing
- [ ] Forge build + test passes
