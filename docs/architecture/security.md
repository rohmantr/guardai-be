# Rug Radar — Security Architecture

**Versi:** 1.0
**Tanggal:** 13 Juli 2026

---

## Threat Model

| Threat | Dampak | Mitigasi |
|--------|--------|----------|
| Oracle manipulasi | Settlement salah | OracleAdapter hanya bisa dipanggil owner/trusted relayer; data diverifikasi on-chain |
| AI agent compromised | Skor risiko palsu | RiskRegistry immutable per token; hanya assessment pertama yang dipakai |
| Reentrancy pool | Dana hilang | ReentrancyGuard + Checks-Effects-Interactions |
| Flash loan attack | Manipulasi odds | Minimum block delay antara open pool dan trading pertama |
| Front-running settlement | Keuntungan tidak adil | Settlement hanya berdasarkan event yang sudah konfirmasi block finality |
| API key leak | Akses tidak sah | Rate limiting + IP whitelist + rotasi key periodik |

## Smart Contract Security

1. **ReentrancyGuard** dari OZ di semua fungsi yang transfer dana
2. **Checks-Effects-Interactions** — state update BEFORE external call
3. **AccessControl** — fungsi sensitive (settle, withdraw) hanya via specific role
4. **Pausable** — emergency pause untuk semua pool (hanya owner)
5. **Pull over push** — payout via `claim()` bukan transfer otomatis
6. **Integer safety** — OpenZeppelin SafeCast, unchecked hanya di loop yang terverifikasi
7. **No delegatecall** — tidak ada proxy pattern di fase awal (YAGNI)

## Backend Security

1. **Input validation** — semua input diperiksa tipe, panjang, format
2. **SQL injection** — parameterized query via TypeORM
3. **Rate limiting** — 100 req/min authenticated, 10 req/min anonymous
4. **CORS** — whitelist origin yang diketahui
5. **Dependency scanning** — `npm audit` di CI pipeline

## API Security

1. **API Key authentication** — key per user, hash stored (bcrypt)
2. **EIP-4361 sign-in** — bind API key ke wallet address
3. **Request signing** — optional untuk mutation endpoints
4. **No secrets in URL** — API key via header, not query param

## AI Output Validation

1. **Probability range check** → [0.0, 1.0], reject otherwise
2. **Reasoning length limit** → max 500 chars
3. **JSON schema validation** → pastikan format sesuai spec
4. **Confidence floor** → probability < 0.5 diberi peringatan di UI
5. **No executable code** → LLM output di-scan untuk sintaks script

## Secret Management

| Secret | Storage | Rotation |
|--------|---------|----------|
| LLM API key | Environment variable / Vault | Monthly |
| RPC endpoint | Environment variable | Per provider |
| Database password | Environment variable + Vault | Quarterly |
| Private key deployer | Hardware wallet / KMS | Per deployment |
| API key salt | Gitignored, generated at setup | Never (rotate salt → invalidate all keys) |

## Rate Limiting

- **Global:** 1000 req/min per IP
- **Authenticated:** 100 req/min per API key
- **Assessment trigger:** 10 req/min per wallet
- **Burst allowance:** 20 req dalam 10 detik

## Replay Attack Prevention

- **Nonce-based:** Setiap transaksi mengandung incrementing nonce
- **Timestamp window:** Signature valid dalam 5 menit
- **Idempotency key:** Mutation endpoint menerima `Idempotency-Key` header
