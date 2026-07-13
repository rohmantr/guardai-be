# ADR-003: Base Network untuk Deployment Produksi

**Status:** Accepted
**Tanggal:** 13 Juli 2026

## Konteks

Kami butuh chain L2 yang cepat, murah, dan memiliki ekosistem token baru (memecoin) yang aktif.

## Keputusan

Menggunakan **Base** (OP Stack L2 oleh Coinbase) sebagai chain utama.

## Alasan

- Biaya transaksi sangat rendah — esensial untuk prediction market dengan volume kecil
- Ekosistem token baru sangat aktif — audiens target produk
- OP Stack memudahkan bridging dari Ethereum mainnet
- Integrasi dengan Base Sepolia untuk staging
- Compatible dengan EVM tooling (Foundry, ethers)

## Konsekuensi

- Terikat dengan Base ecosystem developments
- Perlu Bridge ETH untuk topup kontrak
- Tidak bisa menjangkau chain lain di MVP
