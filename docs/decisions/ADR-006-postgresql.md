# ADR-006: PostgreSQL untuk Database Utama

**Status:** Accepted
**Tanggal:** 13 Juli 2026

## Konteks

Kami butuh database relational untuk menyimpan data token, assessment, pool, posisi, dan resolusi.

## Keputusan

Menggunakan **PostgreSQL** dengan TypeORM sebagai ORM.

## Alasan

- Relational data dengan hubungan jelas antar entity — cocok untuk RDBMS
- PostgreSQL maturity, reliability, dan ekosistem tooling
- TypeORM memberikan type safety dan migration management
- JSONB columns untuk data semi-structured jika diperlukan
- Tidak perlu NoSQL — data volume MVP tidak memerlukan sharding

## Konsekuensi

- Perlu managed PostgreSQL (RDS / Cloud SQL) di production
- Migrasi harus additive di fase awal
- Tidak bisa horizontal scale semudah NoSQL — perlu replikasi read jika scale
