# ADR-001: Foundry sebagai Framework Smart Contract

**Status:** Accepted
**Tanggal:** 13 Juli 2026

## Konteks

Kami membutuhkan framework smart contract yang ringan, cepat, dan mendukung testing Solidity native.

## Keputusan

Menggunakan **Foundry** (forge, cast, anvil) sebagai framework utama.

## Alasan

- Testing native Solidity tanpa JavaScript — lebih cepat dan langsung mereproduksi kondisi on-chain
- `forge test` + `forge fuzz` built-in tanpa setup tambahan
- `anvil` untuk local chain tanpa dependensi eksternal
- `cast` untuk interaksi langsung dari CLI
- Ekosistem Foundry sudah mature dan menjadi standar di proyek DeFi modern

## Konsekuensi

- Tidak bisa menggunakan Hardhat plugins atau ethers.js untuk deployment
- Semua deployment via `forge script`
- Tim harus familiar dengan CLI Foundry
