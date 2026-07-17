# [Nama Service] API Documentation

**Version:** 1.0.0
**Base URL (Production):** `https://api.[domain].com/v1`
**Base URL (Staging):** `https://staging-api.[domain].com/v1`

## Overview

[Deskripsi singkat: apa fungsi service ini, siapa konsumennya — frontend, agent lain, integrasi pihak ketiga]

## Authentication

Semua request (kecuali disebutkan lain) butuh header berikut:

```
X-API-Key: <api-key-kamu>
```

Request tanpa API key atau dengan key tidak valid akan mendapat `401 Unauthorized`.

## Format Error

Semua response gagal memakai format yang seragam:

```json
{
  "error": {
    "code": "ERROR_CODE_SNAKE_CASE",
    "message": "Pesan error yang jelas dan actionable",
    "details": {}
  }
}
```

| HTTP Status | Kapan Dipakai |
|---|---|
| `400` | Input tidak valid — format salah atau field wajib hilang |
| `401` | Autentikasi gagal atau tidak ada |
| `404` | Resource tidak ditemukan |
| `422` | Validasi gagal pada field tertentu (lihat `details`) |
| `429` | Terlalu banyak request dalam periode waktu tertentu |
| `500` | Kesalahan server internal — detail internal tidak di-expose ke client |

## Pagination

Endpoint yang mengembalikan list mendukung parameter berikut:

| Parameter | Tipe | Default | Keterangan |
|---|---|---|---|
| `page` | integer | `1` | Halaman ke berapa |
| `pageSize` | integer | `20` | Maksimum `100` |

Response list selalu menyertakan objek `pagination`:

```json
{
  "data": [ /* ... */ ],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "totalItems": 100
  }
}
```

---

## Endpoints

### [Nama Resource]

#### `GET /[resource]`

[Ringkasan singkat 1 baris — contoh: Daftar semua [resource]]

[Deskripsi lebih detail: kapan dipakai, catatan behavior khusus]

**Query Parameters**

| Nama | Tipe | Wajib | Keterangan |
|---|---|---|---|
| `[queryParamName]` | string | Tidak | [Deskripsi parameter, contoh nilai valid] |
| `page` | integer | Tidak | Lihat bagian Pagination |
| `pageSize` | integer | Tidak | Lihat bagian Pagination |

**Response `200`**

```json
{
  "data": [
    {
      "id": "[contoh-id]",
      "[field1]": "[contoh nilai]",
      "createdAt": "2026-07-17T10:00:00Z"
    }
  ],
  "pagination": { "page": 1, "pageSize": 20, "totalItems": 100 }
}
```

**Error Responses:** `400`, `401`, `429`, `500` — lihat format umum di atas.

---

#### `POST /[resource]`

[Ringkasan singkat — contoh: Buat [resource] baru]

**Request Body**

```json
{
  "[field1]": "[nilai wajib]"
}
```

| Field | Tipe | Wajib | Keterangan |
|---|---|---|---|
| `[field1]` | string | Ya | [Deskripsi field] |

**Response `201`**

```json
{
  "id": "[contoh-id]",
  "[field1]": "[contoh nilai]",
  "createdAt": "2026-07-17T10:00:00Z"
}
```

**Error Responses:** `400`, `401`, `422` — lihat format umum di atas.

---

#### `GET /[resource]/{id}`

[Ambil satu [resource] berdasarkan id]

**Path Parameters**

| Nama | Tipe | Keterangan |
|---|---|---|
| `id` | string | [Deskripsi format id — contoh: address 0x..., UUID, dsb] |

**Response `200`**

```json
{
  "id": "[contoh-id]",
  "[field1]": "[contoh nilai]",
  "createdAt": "2026-07-17T10:00:00Z"
}
```

**Error Responses:** `404`, `500` — lihat format umum di atas.

---

### Webhooks

#### `POST /webhooks/[eventSource]`

Menerima event dari sumber eksternal (contoh: oracle, indexer).

> **Wajib:** validasi signature/HMAC pada setiap request masuk, dan tangani `idempotency key` karena event bisa terkirim ulang oleh pengirim (retry). Tanpa ini, event duplikat bisa memicu efek samping berulang (misal resolusi pool ke-trigger dua kali).

**Request Body**

```json
{
  "eventType": "[contoh: liquidity_pulled]",
  "timestamp": "2026-07-17T10:00:00Z",
  "payload": {}
}
```

| Field | Tipe | Wajib | Keterangan |
|---|---|---|---|
| `eventType` | string | Ya | Jenis event |
| `timestamp` | string (ISO 8601) | Ya | Waktu event terjadi |
| `payload` | object | Ya | Data spesifik per jenis event |

**Response `200`** — event diterima, tidak ada body.

**Error Responses:** `400`, `401` (signature tidak valid) — lihat format umum di atas.

---

## Changelog

| Versi | Tanggal | Perubahan |
|---|---|---|
| 1.0.0 | [tanggal] | Rilis awal |