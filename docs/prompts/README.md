# Rug Radar — AI Prompts

**Versi:** 1.0
**Tanggal:** 13 Juli 2026

---

## Purpose

Direktori ini berisi semua prompt yang digunakan oleh Rug Radar AI Agent. Prompt adalah satu-satunya titik di mana LLM berinteraksi dengan sistem — sehingga setiap prompt harus didokumentasi, divalidasi, dan di-version secara ketat.

## AI Workflow

```
Blockchain Data → Prompt Template → LLM → JSON Output → Validation → Store & Use
```

1. **Data Collection** — Agent mengumpulkan data on-chain token (bytecode functions, liquidity lock, holder concentration)
2. **Prompt Construction** — Data diinjeksi ke prompt template (risk-analysis.md)
3. **LLM Inference** — Prompt dikirim ke model LLM (GPT-4o / Claude)
4. **Output Parsing** — Response JSON diparse dan divalidasi terhadap schema (output-schema.md)
5. **Confidence Scoring** — Confidence dihitung berdasarkan kelengkapan data sumber
6. **Storage & Action** — Assessment valid disimpan, pool prediksi dibuka

## Versioning

Prompt di-version secara independen menggunakan **semantic versioning** — lihat [versioning.md](versioning.md).

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-07-13 | Initial release |

## Prompt Engineering Principles

1. **Deterministic output** — Selalu minta JSON response dengan schema tetap.
2. **Least privilege** — LLM hanya menerima data yang relevan untuk tugasnya.
3. **Transparency over persuasion** — Prompt tidak meminta LLM "yakin" — minta data dan probabilitas.
4. **Validation beyond the prompt** — Output divalidasi secara terprogram, bukan hanya "percaya" LLM.
5. **Fail gracefully** — Jika data tidak lengkap, tetap hasilkan output dengan confidence rendah, bukan error.

## Input/Output Contract

**Input:** Data on-chain terstruktur (token address, risk functions, liquidity status, holder concentration, chain metadata)

**Output:** JSON dengan format:

```json
{
  "probability": 0.0 - 1.0,
  "reasoning": "string (max 200 chars)",
  "confidence": 0.0 - 1.0,
  "riskFactors": ["string", ...]
}
```

Lihat [output-schema.md](output-schema.md) untuk detail schema dan validasi.
