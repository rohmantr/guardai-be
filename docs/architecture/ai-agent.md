# Rug Radar — AI Agent Architecture

**Versi:** 1.0
**Tanggal:** 13 Juli 2026

---

## AI Pipeline

```
Token Deploy → Data Collection → Prompt Generation → LLM → Validation → Confidence → Open Pool
```

## 1. Data Collection

Agent membaca data on-chain token baru dari Base:

| Sinyal | Sumber | Deskripsi |
|--------|--------|-----------|
| Fungsi kontrak berisiko | Bytecode | Mint tak terbatas, blacklist, tax jebakan |
| Liquidity lock status | Liquidity pool | Apakah LP terkunci? |
| Holder konsentrasi | Holder distribution | % top 10 holder |
| Age kontrak | Block timestamp | Berapa lama sejak deploy |

Data collection dilakukan via RPC call ke archive node — tidak ada indexer pihak ketiga (YAGNI untuk fase awal).

## 2. Prompt Generation

Template prompt yang mengemas data on-chain ke format terstruktur untuk LLM:

```
[SISTEM]
Anda adalah risk assessor token kripto. Berdasarkan data on-chain berikut,
berikan probabilitas token ini adalah rug-pull (0.0 - 1.0) dan alasan singkat.

[DATA ON-CHAIN]
- Alamat: {address}
- Fungsi berisiko: {riskFunctions}  // mint tak terbatas, blacklist, dll
- Liquidity locked: {liquidityLocked}
- Top 10 holder: {topHolderPercent}%
- Umur kontrak: {age} blok

[OUTPUT]
Hanya JSON: {"probability": float, "reasoning": string, "confidence": float}
```

## 3. LLM

Menggunakan model LLM (GPT-4o / Claude / Gemini) via API. Hasil diparse dari JSON response.

- **Timeout:** 15 detik per request
- **Max retries:** 2
- **Max tokens output:** 200

## 4. Output Validation

Setiap response LLM divalidasi sebelum digunakan:

```typescript
interface LLMOutput {
  probability: number;   // 0.0 - 1.0
  reasoning: string;     // maks 200 char
  confidence: number;    // 0.0 - 1.0
}
```

Validation rules:
- `probability` dalam range [0.0, 1.0]
- `confidence` dalam range [0.0, 1.0]
- `reasoning` tidak kosong
- Jika gagal parse → retry atau fallback ke probability = 0.5

## 5. Confidence Scoring

Confidence ditentukan oleh LLM berdasarkan kelengkapan data:

| Kondisi | Confidence |
|---------|-----------|
| Semua sinyal tersedia | 0.9 - 1.0 |
| Liquidity lock tidak terverifikasi | 0.6 - 0.8 |
| Bytecode tidak bisa dibaca | 0.3 - 0.5 |
| Data minimal | 0.1 - 0.3 |

Confidence < 0.5 → token tetap diproses tetapi dengan peringatan "data terbatas" di frontend.

## 6. Retry Strategy

| Skenario | Retry | Fallback |
|----------|-------|----------|
| LLM timeout (15s) | 2x, backoff 2s | probability = 0.5, confidence = 0.1 |
| JSON parse error | 2x dengan prompt diperbaiki | probability = 0.5 |
| RPC error | 3x, backoff 1s | Cancel assessment, retry di worker cycle berikutnya |
| Rate limit | Exponential backoff (30s, 60s, 120s) | Queue untuk cycle berikutnya |

## 7. Failure Handling

Jika semua retry gagal:
1. Token dicatat sebagai `assessment_failed`
2. Tidak membuka pool prediksi
3. Log error ke backend
4. Alert ke admin jika > 5 kegagalan berturut-turut
