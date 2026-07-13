# ADR-004: AI Risk Engine via LLM

**Status:** Accepted
**Tanggal:** 13 Juli 2026

## Konteks

Kami butuh menghasilkan probabilitas rug-pull yang mempertimbangkan sinyal kualitatif (fungsi kontrak, pola kepemilikan) — bukan hanya rule statis.

## Keputusan

Menggunakan **LLM (GPT-4o / Claude)** untuk sintesis sinyal menjadi probabilitas, dengan struktur output JSON yang ketat.

## Alasan

- Setiap kontrak punya kombinasi fungsi unik — rule engine statis tidak cukup
- LLM bisa memberikan reasoning yang bisa ditampilkan ke pengguna (transparansi)
- Cukup untuk MVP tanpa perlu training model sendiri
- Output JSON memungkinkan validasi terprogram

## Konsekuensi

- Biaya per-request LLM (per token yang di-scan)
- Latensi tambahan (2-5 detik per assess)
- Perlu fallback jika LLM down
- LLM tidak pernah memegang kendali dana — settlement murni on-chain
