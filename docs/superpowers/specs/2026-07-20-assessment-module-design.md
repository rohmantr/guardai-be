# Specification: Assessment Module + AI Agent

**Versi:** 1.0.1  
**Tanggal:** 20 Juli 2026  
**Status:** Approved  

---

## 1. Overview

Modul assessment mengintegrasikan LLM untuk melakukan scoring risiko pada token yang terdeteksi di Base, serta menyediakan endpoint manual trigger `/api/v1/assessments`.

---

## 2. API Endpoints

### `POST /api/v1/assessments`
Memicu penilaian risiko secara manual untuk alamat token tertentu.

- **Authentication:** Header `X-API-Key` dicocokkan dengan env variable `INTERNAL_API_KEY`.
- **Rate Limit:** Maksimum 5 request per menit per API key.
- **Request Body:**
  ```json
  {
    "token_address": "0x1234567890123456789012345678901234567890"
  }
  ```
- **Response `201 Created`:** (Jika assessment baru berhasil dibuat)
  ```json
  {
    "success": true,
    "data": {
      "id": "2b4f6d8e-9c0a-5d3e-0f1a-2b3c4d5e6f7a",
      "token_id": "1a3e5c7d-8b9a-4c2d-9e0f-1a2b3c4d5e6f",
      "probability": 0.85,
      "reasoning": "Token contains blacklist capabilities which allow the deployer to freeze funds at any time.",
      "confidence": 0.90,
      "llm_model": "gpt-4o-mini",
      "source": "llm",
      "assessed_at": "2026-07-20T15:05:00Z",
      "created_at": "2026-07-20T15:05:01Z"
    }
  }
  ```
- **Response `200 OK`:** (Jika mengembalikan record lama hasil dedup window yang sukses dalam 10 menit terakhir)
- **Error `400 Bad Request`:** Format address salah atau payload tidak valid.
- **Error `404 Not Found`:** Token tidak terdaftar di database.

### `GET /api/v1/assessments/{id}`
Mengambil detail assessment berdasarkan ID assessment.

- **Response `200 OK`:**
  ```json
  {
    "success": true,
    "data": {
      "id": "2b4f6d8e-9c0a-5d3e-0f1a-2b3c4d5e6f7a",
      "token_id": "1a3e5c7d-8b9a-4c2d-9e0f-1a2b3c4d5e6f",
      "probability": 0.85,
      "reasoning": "...",
      "confidence": 0.90,
      "llm_model": "gpt-4o-mini",
      "source": "llm",
      "assessed_at": "2026-07-20T15:05:00Z",
      "created_at": "2026-07-20T15:05:01Z"
    }
  }
  ```
- **Error `404 Not Found`:** ID assessment tidak ditemukan (Error code `ASSESSMENT_NOT_FOUND`).

---

## 3. Package Structure

Semua logic AI Agent akan ditempatkan di package `backend/assessment` untuk pemisahan concern yang bersih.

```
backend/
├── assessment/
│   ├── controller.go  # HTTP API Request Handlers
│   ├── service.go     # Business Logic & Orchestration
│   ├── repository.go  # Database queries
│   └── agent/         # AI Agent Sub-package
│       ├── client.go    # OpenAI LLM HTTP Client
│       ├── prompt.go    # System and user prompts
│       ├── validator.go # Output Validation & Parsing
│       └── agent.go     # Execution Pipeline
```

---

## 4. AI Agent Pipeline & Rules

### Dedup Window & Cache Policy
- Dedup window berdurasi **10 menit**.
- Dedup **hanya berlaku** jika assessment terakhir sukses (`source = 'llm'`).
- Jika assessment terakhir gagal (`source = 'fallback'`), request baru akan membypass cache dan memicu LLM call baru.

### LLM Client (`agent/client.go`)
- HTTP POST request ke `https://api.openai.com/v1/chat/completions` dengan structured output (`response_format: {"type": "json_object"}`).
- **Overhead Safety Timeout:** Total budget timeout context diset **18 detik**.
- **Per-attempt timeout:** Maksimum **4 detik** per attempt.
- **Retry Policy:** 2x retry dengan exponential backoff:
  - Error `429` atau `5xx` -> Delay 1s (retry 1), delay 2s (retry 2).
  - Error `401`/`403`/`400` -> Fail immediately tanpa retry.

### Validator & Parsing (`agent/validator.go`)
- Validasi strict range `probability` [0.0, 1.0] dan `confidence` [0.0, 1.0].
- Filter enum `riskFactors` terhadap subset yang diizinkan.
- Truncate `reasoning` pada word boundary terdekat di bawah 200 karakter.

### Fallback Behavior
- Jika LLM gagal/timeout setelah semua retries, fallback disuntikkan:
  - `probability`: `0.5`
  - `confidence`: `0.1`
  - `reasoning`: `"Assessment failed due to LLM error. Defaulting to neutral risk."`
  - `riskFactors`: `["insufficient_data"]`
  - `source`: `"fallback"`
- **Fail-closed:** Token dengan `source = 'fallback'` **dilarang membuka prediction pool** di level backend.

---

## 5. Database Schema & Migration

Menambahkan kolom `source` dan `raw_response` pada database. File migration baru akan dibuat di `backend/db/migrations/20260720000001-add-source-and-raw-to-assessments.sql`.

```sql
ALTER TABLE risk_assessments 
ADD COLUMN IF NOT EXISTS source VARCHAR(20) NOT NULL DEFAULT 'llm',
ADD COLUMN IF NOT EXISTS raw_response TEXT;
```

---

## 6. Assumptions & Limitations

- **Sync Pattern Assumption:** Sync pattern (blocking call) saat ini valid karena endpoint hanya diakses oleh background worker / admin CLI internal. Jika kelak diakses oleh frontend user-facing, endpoint harus direvisit menjadi async pattern (`202 Accepted` + polling).
- **Known Limitation (Stuck Pools):** Jika token terus-menerus menghasilkan fallback (LLM down berkelanjutan), pool tidak akan terbuka secara otomatis. Hal ini memerlukan manual review atau trigger ulang ketika koneksi pulih.
- **ponytail: fallback-recovery — manual review/retry mechanism, add ketika admin dashboard tersedia**
