# Rug Radar — Domain Glossary

**Versi:** 1.0
**Tanggal:** 13 Juli 2026

---

## Rug Radar Concepts

| Term | Definition |
|------|-----------|
| **Rug Radar** | AI-powered rug-pull prediction market on Base. Agent mendeteksi token baru, menilai risiko via LLM, dan membuka pool prediksi YES/NO. |
| **Agent** | Sistem AI off-chain yang membaca data on-chain dan menghasilkan skor probabilitas rug-pull. |
| **Assessment** | Hasil analisis agent untuk satu token: probability, reasoning, confidence, risk factors. |
| **Prediction Pool** | Kontrak untuk satu token di mana trader bisa membeli posisi YES (rug) atau NO (safe). |
| **Position** | Posisi trader di pool — YES (rug akan terjadi) atau NO (aman). |
| **Settlement** | Proses penyelesaian pool berdasarkan data oracle. Pemenang menerima payout. |
| **Attestation** | Pencatatan hasil settlement ke EAS untuk track record agent. |

## Prediction Market Terminology

| Term | Definition |
|------|-----------|
| **YES Position** | Prediksi bahwa token akan rug-pull. Menang jika liquidity ditarik dalam waktu yang ditentukan. |
| **NO Position** | Prediksi bahwa token aman. Menang jika liquidity tidak ditarik. |
| **Payout** | Jumlah yang diterima pemenang setelah settlement. Proporsional terhadap total pool. |
| **Odds** | Rasio antara YES dan NO pool — mencerminkan probabilitas pasar. |
| **Liquidity Pull** | Event on-chain di mana deployer menarik semua LP — indikasi rug-pull. |
| **Binary Pool** | Pool dengan dua outcome: YES atau NO. Tidak ada outcome lain. |

## Web3 Concepts

| Term | Definition |
|------|-----------|
| **Base** | L2 blockchain oleh Coinbase (OP Stack). Chain utama Rug Radar. |
| **RPC** | Remote Procedure Call — endpoint untuk berinteraksi dengan blockchain. |
| **Bytecode** | Kode smart contract dalam format hex. Rug Radar membaca bytecode untuk mengidentifikasi fungsi berisiko. |
| **Liquidity Lock** | Mekanisme mengunci LP token di smart contract sehingga tidak bisa ditarik oleh deployer. |
| **Holder Concentration** | Persentase total supply yang dimiliki oleh holder teratas — indikator potensi manipulasi. |
| **EAS** | Ethereum Attestation Service — protokol untuk membuat attestations on-chain. |
| **LP Token** | Liquidity Provider token — representasi share di liquidity pool. |
| **ERC-4337** | Account abstraction standard — memungkinkan smart account. |
| **Archive Node** | Full node yang menyimpan state historis — diperlukan untuk membaca data on-chain lama. |

## AI Terminology

| Term | Definition |
|------|-----------|
| **LLM** | Large Language Model — model AI yang digunakan untuk sintesis sinyal risiko (GPT-4o, Claude). |
| **Prompt** | Instruksi yang dikirim ke LLM berisi data on-chain dan instruksi format output. |
| **System Prompt** | Bagian prompt yang mendefinisikan role dan aturan untuk LLM. |
| **Confidence** | Tingkat keyakinan LLM terhadap assessment-nya berdasarkan kelengkapan data input. |
| **Hallucination** | Ketika LLM menghasilkan informasi yang tidak akurat atau fiktif. |
| **Prompt Injection** | Serangan di mana data input berisi instruksi yang memanipulasi output LLM. |

## Technical Concepts

| Term | Definition |
|------|-----------|
| **Foundry** | Framework Solidity (forge, cast, anvil) yang digunakan untuk development dan testing. |
| **OpenZeppelin** | Library smart contract yang sudah diaudit — digunakan untuk Ownable, ReentrancyGuard, dll. |
| **OracleAdapter** | Kontrak yang menghubungkan event on-chain (liquidity pull) ke PredictionPool. |
| **RiskRegistry** | Kontrak yang menyimpan skor risiko per token secara immutable. |
| **Treasury** | Kontrak yang mengelola fee protokol dan payout. |
| **SettlementManager** | Kontrak yang mengatur jadwal settlement dan memastikan finality. |
| **Dead-Letter Queue (DLQ)** | Queue untuk event yang gagal diproses setelah semua retry. |

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Smart Contract | PascalCase | `PredictionPool`, `OracleAdapter` |
| Function | camelCase | `buyPosition`, `getPoolInfo` |
| Variable | camelCase | `poolId`, `yesPoolAmount` |
| Enum | PascalCase | `Side`, `PoolStatus` |
| Error | PascalCase | `PoolNotActive`, `InsufficientPayment` |
| Event | PascalCase | `PoolCreated`, `PositionPurchased` |
| Database Table | snake_case, plural | `prediction_pools`, `risk_assessments` |
| Database Column | snake_case | `has_unlimited_mint`, `pool_id` |
| API Endpoint | kebab-case, plural | `/api/v1/tokens`, `/api/v1/pools` |
| API Field (JSON) | snake_case | `risk_factors`, `user_address` |
| Environment Variable | UPPER_SNAKE_CASE | `DATABASE_URL`, `LLM_API_KEY` |
| Error Code | UPPER_SNAKE_CASE | `RR_AI_LLM_TIMEOUT` |
