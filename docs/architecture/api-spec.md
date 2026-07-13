# Rug Radar — API Specification

**Versi:** 1.0
**Tanggal:** 13 Juli 2026

---

## Conventions

- **Base URL:** `/api/v1`
- **Format:** JSON
- **Method:** RESTful (GET, POST, PUT/PATCH)
- **Case:** snake_case untuk field JSON
- **Time:** ISO 8601 UTC

## Standard Response Format

```json
{
  "success": true,
  "data": { ... },
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 100
  }
}
```

## Error Format

```json
{
  "success": false,
  "error": {
    "code": "TOKEN_NOT_FOUND",
    "message": "Token with address 0x... not found",
    "details": {}
  }
}
```

Error codes: `Uppercase_Snake_Case` yang mendeskripsikan error.

## Pagination

- **Parameter:** `?page=1&limit=20`
- **Default:** page=1, limit=20
- **Max:** limit=100
- **Response:** meta object dengan page, limit, total

## Authentication

- **Method:** API Key via header `X-API-Key`
- **Scope:** Key terikat ke alamat wallet (EIP-4361 sign-in)
- **Rate limit:** 100 req/min per key (unauthenticated: 10 req/min)

## API Versioning

- **Path-based:** `/api/v1/...`
- **Header-based fallback:** `Accept: application/vnd.rugradar.v1+json`
- **Deprecation:** Header `Sunset` dan `Deprecation` pada response endpoint lama

## Endpoints

### Tokens

| Method | Path | Deskripsi |
|--------|------|-----------|
| GET | /tokens | List token dengan filtering |
| GET | /tokens/:address | Detail token + assessment terbaru |
| GET | /tokens/:address/assessments | Riwayat assessment token |

### Assessments

| Method | Path | Deskripsi |
|--------|------|-----------|
| GET | /assessments/:id | Detail assessment |
| POST | /assessments | Trigger assessment manual |

### Pools

| Method | Path | Deskripsi |
|--------|------|-----------|
| GET | /pools | List prediction pools |
| GET | /pools/:id | Detail pool (odds, volume, status) |
| POST | /pools/:id/positions | Beli posisi (signature-based) |

### Positions

| Method | Path | Deskripsi |
|--------|------|-----------|
| GET | /positions | List posisi user |
| GET | /positions/:id | Detail posisi |

### Stats

| Method | Path | Deskripsi |
|--------|------|-----------|
| GET | /stats/overview | Ringkasan platform |
| GET | /stats/accuracy | Track record akurasi agent |

## Endpoint Naming Rules

1. **Plural nouns** untuk collections: `/tokens`, `/pools`
2. **Nested** untuk relasi: `/tokens/:address/assessments`
3. **No verbs** di path: gunakan POST untuk aksi, bukan `/createToken`
4. **Consistent params:** filter via query string, sort via `?sort=field:asc`
