# ADR-002: OpenZeppelin untuk Standar Kontrak

**Status:** Accepted
**Tanggal:** 13 Juli 2026

## Konteks

Kami membutuhkan implementasi standar yang sudah diaudit untuk Ownable, AccessControl, ReentrancyGuard, dan Pausable.

## Keputusan

Menggunakan **OpenZeppelin Contracts** v5.x (Solidity ^0.8.28 compatible).

## Alasan

- Implementasi yang sudah diaudit dan digunakan ribuan proyek
- Mengurangi attack surface dibanding implementasi custom
- Ownable2Step, AccessControl, ReentrancyGuard, SafeERC20 tersedia out-of-the-box
- Update keamanan dirilis cepat jika ada CVE

## Konsekuensi

- Dependensi eksternal pada package OpenZeppelin via forge install
- Perlu monitor rilis upstream untuk security patch
