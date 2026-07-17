# Rug Radar Token Module API Documentation

**Version:** 1.0.0
**Base URL (Production):** `https://api.rugradar.ai/api/v1`
**Base URL (Staging):** `https://staging-api.rugradar.ai/api/v1`

## Overview

Dokumentasi API untuk Modul Token dari Rug Radar. Modul ini bertanggung jawab untuk mendeteksi token baru, membaca bytecode on-chain, mendeteksi fungsi berisiko (seperti unlimited mint dan blacklist), dan mengelola riwayat penilaian risiko (risk assessments) berbasis kecerdasan buatan. API ini digunakan oleh frontend klien, bot monitoring, dan agen AI dalam ekosistem Rug Radar.

## Format Error

Semua response gagal memakai format yang seragam dari middleware error backend:

```json
{
  "status": "error",
  "message": "Pesan error yang jelas dan actionable",
  "code": "ERROR_CODE_SNAKE_CASE"
}
```

| HTTP Status | Kode Error (`code`) | Kapan Dipakai |
|---|---|---|
| `400` | `INVALID_ADDRESS` | Format alamat ethereum tidak valid |
| `404` | `TOKEN_NOT_FOUND` | Token dengan alamat tersebut tidak ditemukan |
| `500` | `INTERNAL_SERVER_ERROR` | Terjadi kesalahan pada server internal |

## Pagination

Endpoint list mendukung parameter paginasi berikut:

| Parameter | Tipe | Default | Keterangan |
|---|---|---|---|
| `page` | integer | `1` | Nomor halaman yang ingin diambil |
| `limit` | integer | `20` | Batas maksimum token per halaman (maksimum `100`) |
| `search` | string | `""` | Pencarian substring alamat token (case-insensitive) |

Response list menyertakan objek `meta` untuk metadata paginasi:

```json
{
  "success": true,
  "data": [ /* ... */ ],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 12
  }
}
```

---

## Endpoints

### Tokens

#### `GET /tokens`

Daftar semua token yang terdeteksi di dalam database dengan paginasi dan filter pencarian.

**Query Parameters**

| Nama | Tipe | Wajib | Keterangan |
|---|---|---|---|
| `page` | integer | Tidak | Lihat bagian Pagination |
| `limit` | integer | Tidak | Lihat bagian Pagination |
| `search` | string | Tidak | Kata kunci pencarian alamat token |

**Response `200`**

```json
{
  "success": true,
  "data": [
    {
      "id": "1a3e5c7d-8b9a-4c2d-9e0f-1a2b3c4d5e6f",
      "address": "0x1234567890123456789012345678901234567890",
      "chain_id": 8453,
      "deployer": "0x9876543210987654321098765432109876543210",
      "deployed_at": "2026-07-17T15:00:00Z",
      "has_unlimited_mint": false,
      "has_blacklist": true,
      "has_tax": false,
      "liquidity_locked": null,
      "top_holder_concentration": null,
      "created_at": "2026-07-17T15:00:05Z",
      "updated_at": "2026-07-17T15:00:05Z"
    }
  ],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 1
  }
}
```

**Error Responses:** `500`

---

#### `GET /tokens/{address}`

Mengambil detail satu token beserta penilaian risiko (`latest_assessment`) terbaru berdasarkan alamat token.

**Path Parameters**

| Nama | Tipe | Keterangan |
|---|---|---|
| `address` | string | Alamat ethereum token (format `0x` diikuti oleh 40 karakter heksadesimal) |

**Response `200`**

```json
{
  "success": true,
  "data": {
    "id": "1a3e5c7d-8b9a-4c2d-9e0f-1a2b3c4d5e6f",
    "address": "0x1234567890123456789012345678901234567890",
    "chain_id": 8453,
    "deployer": "0x9876543210987654321098765432109876543210",
    "deployed_at": "2026-07-17T15:00:00Z",
    "has_unlimited_mint": false,
    "has_blacklist": true,
    "has_tax": false,
    "liquidity_locked": true,
    "top_holder_concentration": 0.4500,
    "created_at": "2026-07-17T15:00:05Z",
    "updated_at": "2026-07-17T15:00:05Z",
    "latest_assessment": {
      "id": "2b4f6d8e-9c0a-5d3e-0f1a-2b3c4d5e6f7a",
      "token_id": "1a3e5c7d-8b9a-4c2d-9e0f-1a2b3c4d5e6f",
      "probability": 0.8500,
      "reasoning": "Token contains blacklist capabilities which allow the deployer to freeze funds at any time.",
      "confidence": 0.9000,
      "llm_model": "gpt-4o-mini",
      "assessed_at": "2026-07-17T15:05:00Z",
      "created_at": "2026-07-17T15:05:01Z"
    }
  }
}
```

**Error Responses:**

* **`400 Bad Request`** — Format address salah.
  ```json
  {
    "status": "error",
    "message": "Invalid ethereum address format",
    "code": "INVALID_ADDRESS"
  }
  ```
* **`404 Not Found`** — Token tidak terdaftar.
  ```json
  {
    "status": "error",
    "message": "Token not found",
    "code": "TOKEN_NOT_FOUND"
  }
  ```

---

#### `GET /tokens/{address}/assessments`

Mengambil daftar seluruh riwayat penilaian risiko (risk assessments) untuk token tertentu diurutkan dari yang paling baru.

**Path Parameters**

| Nama | Tipe | Keterangan |
|---|---|---|
| `address` | string | Alamat ethereum token |

**Response `200`**

```json
{
  "success": true,
  "data": [
    {
      "id": "2b4f6d8e-9c0a-5d3e-0f1a-2b3c4d5e6f7a",
      "token_id": "1a3e5c7d-8b9a-4c2d-9e0f-1a2b3c4d5e6f",
      "probability": 0.8500,
      "reasoning": "Token contains blacklist capabilities which allow the deployer to freeze funds at any time.",
      "confidence": 0.9000,
      "llm_model": "gpt-4o-mini",
      "assessed_at": "2026-07-17T15:05:00Z",
      "created_at": "2026-07-17T15:05:01Z"
    }
  ]
}
```

**Error Responses:**

* **`400 Bad Request`** — Format address salah.
  ```json
  {
    "status": "error",
    "message": "Invalid ethereum address format",
    "code": "INVALID_ADDRESS"
  }
  ```
* **`404 Not Found`** — Token tidak ditemukan.
  ```json
  {
    "status": "error",
    "message": "Token not found",
    "code": "TOKEN_NOT_FOUND"
  }
  ```

---

## Changelog

| Versi | Tanggal | Perubahan |
|---|---|---|
| 1.0.0 | 2026-07-17 | Inisialisasi awal dokumentasi API Modul Token berbasis Go |
