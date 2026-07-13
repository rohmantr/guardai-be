# Business Requirements Document (BRD)
## Rug Radar — Prediksi Rug-Pull 24 Jam + Prediction Market Otomatis

**Versi:** 1.0
**Tanggal:** 13 Juli 2026
**Track:** AI Agent x Web3 Hackathon

---

## 1. Ringkasan Eksekutif

Rug Radar adalah agent AI otonom yang membaca kontrak token baru di Base, menghasilkan probabilitas rug-pull dalam 24 jam, dan mengubah probabilitas itu menjadi pasar prediksi biner (YES/NO) yang settlement-nya otomatis lewat smart contract. Pengguna yang yakin sebuah token akan rug bisa membeli posisi YES; pengguna yang percaya token aman bisa mengambil posisi NO — secara payoff ini setara dengan short-selling risiko, tanpa perlu infrastruktur perpetual/borrow yang berat untuk token kecil.

Proyek ini dirancang untuk dua tujuan sekaligus: (1) menang di format hackathon dengan demo yang bisa dipahami juri dalam hitungan detik, dan (2) punya jalur realistis untuk dilanjutkan pasca-hackathon karena akurasi resolusinya terekam publik dan menjadi track record yang bisa dipercaya dari waktu ke waktu.

## 2. Latar Belakang & Masalah

Rug-pull adalah salah satu risiko paling umum dan paling merugikan di ekosistem token baru (terutama di chain berbiaya rendah seperti Base, tempat deploy token baru terjadi ribuan kali per hari). Saat ini:

- Tidak ada sinyal risiko yang bisa diverifikasi publik dan tersedia dalam hitungan detik setelah token deploy.
- Alat yang ada (contract scanner, honeypot checker) umumnya berbasis rule statis (cek fungsi blacklist, cek ownership) — tidak bisa mensintesis banyak sinyal kualitatif sekaligus menjadi satu penilaian probabilistik.
- Tidak ada mekanisme bagi orang yang skeptis terhadap sebuah token untuk memonetisasi keyakinannya tanpa infrastruktur trading derivatif yang rumit.

## 3. Tujuan Bisnis

| Tujuan | Deskripsi |
|---|---|
| Tujuan Hackathon | Demo end-to-end yang bisa dipahami juri dalam ±3 menit, dengan hook yang visceral (uang, taruhan, menang-kalah) |
| Tujuan Produk | Membangun track record akurasi agent yang terekam on-chain, sebagai fondasi kredibilitas jangka panjang |
| Tujuan Ekosistem | Menyediakan sinyal risiko token baru yang publik, trustless, dan real-time untuk komunitas Base |

## 4. Target Pengguna & Pasar

- **Trader ritel di token baru/memecoin** — butuh sinyal cepat sebelum masuk posisi.
- **"Skeptic trader"** — pengguna yang secara aktif ingin memonetisasi keyakinan bahwa sebuah token akan gagal, tanpa harus buka short di venue derivatif terpisah.
- **Komunitas Base yang memantau token baru** — pengguna kasual yang sekadar ingin tahu status risiko sebelum membeli.

Pasar bergerak sejalan dengan volume deploy token baru di chain berbiaya rendah — sebuah tren yang terus berlanjut selama biaya deploy tetap murah dan minat komunitas terhadap token baru tetap tinggi.

## 5. Proposisi Nilai

- **Untuk trader:** satu angka probabilitas yang mudah dipahami, bukan laporan audit teknis yang butuh keahlian membaca.
- **Untuk skeptic trader:** cara langsung memonetisasi keyakinan risiko tanpa infrastruktur short kompleks.
- **Untuk ekosistem:** riwayat akurasi agent yang publik dan terverifikasi, bukan janji marketing.

## 6. Ruang Lingkup

### Dalam Lingkup (untuk MVP hackathon)
- Deteksi token baru di satu chain (Base) secara otomatis.
- Agent membaca kontrak + liquidity lock status + konsentrasi holder teratas.
- Agent menghasilkan probabilitas awal (odds) dan alasan singkat.
- Pool prediksi YES/NO sederhana per token.
- Resolusi otomatis berbasis event on-chain (liquidity-pull terdeteksi dalam 24 jam).
- Attestasi hasil resolusi (EAS) sebagai track record publik.

### Luar Lingkup (untuk MVP hackathon)
- Multi-chain support.
- Model odds yang di-fine-tune dengan data historis besar (cukup heuristik + LLM reasoning untuk MVP).
- Mekanisme dispute/challenge terhadap hasil resolusi.
- Custodial wallet atau KYC.
- Kepatuhan regulasi penuh terhadap produk derivatif/prediction market di berbagai yurisdiksi — ini perlu kajian hukum terpisah sebelum diluncurkan sebagai produk nyata pasca-hackathon.

## 7. Model Bisnis / Monetisasi (arah jangka panjang, bukan fokus MVP)

Potensi sumber pendapatan pasca-hackathon: fee kecil dari setiap pool prediksi yang settle, dan lisensi akses ke skor risiko agent (query berbayar) untuk agent/dApp lain yang ingin mengintegrasikan sinyal Rug Radar ke alur kerja mereka sendiri.

## 8. Pemangku Kepentingan

| Peran | Kepentingan |
|---|---|
| Tim builder (kamu) | Membangun dan mendemokan proyek untuk hackathon |
| Juri hackathon | Menilai kejelasan masalah, kualitas demo, dan penggunaan AI + chain yang esensial |
| Pengguna pool prediksi | Ingin sinyal risiko cepat dan/atau ingin memonetisasi keyakinan |
| Sponsor protokol (Base, dsb) | Menilai kedalaman integrasi teknis jika mengikuti bounty track terkait |

## 9. Risiko Bisnis & Regulasi

- **Risiko regulasi:** pasar prediksi terhadap "kegagalan" sebuah aset finansial bisa masuk area abu-abu gambling/derivatif di beberapa yurisdiksi. Ini bukan penghalang untuk build hackathon, tapi wajib jadi catatan due diligence hukum sebelum dilanjutkan sebagai produk nyata.
- **Risiko reputasi:** akurasi agent yang buruk di awal bisa merusak kepercayaan — mitigasi lewat transparansi penuh (semua verdict dan hasil tercatat via EAS, termasuk yang salah).
- **Risiko manipulasi:** aktor jahat berpotensi memanipulasi sinyal on-chain (mis. liquidity lock palsu) untuk mempengaruhi odds — perlu dicatat sebagai batasan model di MVP, bukan diselesaikan sepenuhnya.

## 10. Metrik Keberhasilan

**Untuk hackathon:**
- Demo end-to-end berjalan mulus dalam ≤3 menit.
- Juri memahami proposisi nilai tanpa penjelasan tambahan.

**Untuk kelanjutan produk (indikatif, bukan target keras):**
- Akurasi resolusi verdict dibanding kejadian rug aktual.
- Jumlah token yang berhasil dipantau otomatis per hari.
- Volume pool prediksi yang terbentuk secara organik.

## 11. Timeline (Skala Hackathon)

Mengikuti jendela submission hackathon yang berlaku (registrasi → submission → demo day). Detail breakdown minggu-per-minggu ada di PRD terkait, bagian Roadmap Build.