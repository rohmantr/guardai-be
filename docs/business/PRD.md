# Product Requirements Document (PRD)
## Rug Radar — Prediksi Rug-Pull 24 Jam + Prediction Market Otomatis

**Versi:** 1.0
**Tanggal:** 13 Juli 2026
**Terkait:** Rug Radar BRD v1.0

---

## 1. Overview Produk

Rug Radar adalah agent AI otonom yang memantau token baru di Base, membaca kontraknya, dan menghasilkan probabilitas rug-pull dalam 24 jam ke depan. Probabilitas ini langsung dijadikan harga awal untuk pool prediksi biner (YES = akan rug, NO = tidak akan rug) yang settlement-nya otomatis lewat smart contract begitu event on-chain yang relevan terdeteksi (misal liquidity ditarik mendadak).

## 2. Masalah yang Dipecahkan

Lihat BRD bagian 2 untuk konteks bisnis lengkap. Singkatnya: tidak ada sinyal risiko token baru yang (a) real-time, (b) mensintesis sinyal kualitatif bukan cuma rule statis, dan (c) bisa langsung dimonetisasi oleh pengguna yang yakin akan risikonya.

## 3. Persona Pengguna

| Persona | Kebutuhan |
|---|---|
| Trader cepat | Butuh satu angka probabilitas sebelum masuk posisi beli |
| Skeptic trader | Ingin buka posisi YES untuk memonetisasi keyakinan token akan rug |
| Believer trader | Ingin buka posisi NO untuk "membela" keyakinan token aman, sekaligus dapat yield dari premi lawan |
| Juri/Reviewer (khusus konteks hackathon) | Butuh memahami value proposition dan melihat agent bekerja dalam waktu singkat |

## 4. User Stories

- Sebagai trader, saya ingin melihat skor risiko sebuah token baru dalam beberapa detik setelah deploy, agar saya bisa memutuskan cepat.
- Sebagai skeptic trader, saya ingin membeli posisi YES pada token yang saya curigai rug, agar saya bisa profit jika keyakinan saya benar.
- Sebagai believer trader, saya ingin membeli posisi NO pada token yang saya percaya aman, agar saya dapat premi dari pihak yang salah.
- Sebagai pengguna umum, saya ingin melihat riwayat akurasi agent ini secara publik, agar saya bisa menilai seberapa layak dipercaya sinyalnya.

## 5. Alur Produk (End-to-End)

1. **Deteksi:** Agent memantau event deploy kontrak baru di Base.
2. **Analisis:** Agent membaca kode kontrak (fungsi mint/blacklist/tax), status liquidity lock, dan konsentrasi holder teratas.
3. **Skoring:** LLM mensintesis sinyal-sinyal itu menjadi probabilitas (misal "73% RUG_LIKELY dalam 24 jam") plus satu kalimat alasan.
4. **Pembukaan pool:** Pool prediksi YES/NO otomatis terbuka untuk token tersebut, dengan harga awal mengikuti probabilitas dari agent.
5. **Partisipasi:** Pengguna membeli posisi YES atau NO dalam jendela 24 jam.
6. **Resolusi:** Oracle mendeteksi event liquidity-pull (atau ketiadaannya) di akhir jendela 24 jam.
7. **Settlement:** Smart contract membayar otomatis ke posisi yang menang.
8. **Attestasi:** Hasil resolusi (verdict awal vs kejadian aktual) dicatat via EAS sebagai track record publik agent.

## 6. Requirement Fungsional (Scope MVP Hackathon)

| ID | Requirement | Prioritas |
|---|---|---|
| F1 | Sistem mendeteksi deploy token baru di Base secara otomatis | Wajib |
| F2 | Agent membaca fungsi kontrak berisiko (mint tak terbatas, blacklist, tax jebakan) | Wajib |
| F3 | Agent membaca status liquidity lock | Wajib |
| F4 | Agent membaca konsentrasi holder teratas | Wajib |
| F5 | LLM menghasilkan probabilitas + alasan singkat dari sinyal F2–F4 | Wajib |
| F6 | Pool prediksi YES/NO terbentuk otomatis dengan harga awal dari F5 | Wajib |
| F7 | Pengguna dapat membeli posisi YES/NO melalui antarmuka sederhana | Wajib |
| F8 | Oracle mendeteksi event liquidity-pull untuk resolusi | Wajib |
| F9 | Settlement otomatis ke posisi pemenang | Wajib |
| F10 | Attestasi hasil resolusi via EAS | Wajib |
| F11 | Dashboard riwayat akurasi agent (opsional, jika waktu memungkinkan) | Bagus untuk dimiliki |
| F12 | Dukungan multi-chain | Di luar scope MVP |
| F13 | Mekanisme dispute/challenge hasil resolusi | Di luar scope MVP |

## 7. Requirement Non-Fungsional

- **Latensi:** skor risiko harus tersedia dalam hitungan detik-menit setelah deploy token, bukan jam — ini kritikal untuk relevansi produk.
- **Transparansi:** alasan di balik setiap probabilitas harus bisa ditampilkan ke pengguna, bukan angka hitam-kotak.
- **Auditabilitas:** setiap verdict dan hasil resolusi harus tercatat permanen dan dapat diverifikasi publik (via EAS).
- **Keandalan oracle:** deteksi event liquidity-pull harus berbasis data on-chain langsung, bukan sumber eksternal yang bisa dimanipulasi dengan mudah.

## 8. Arsitektur Teknis & Stack

| Komponen | Teknologi |
|---|---|
| Chain utama | Base |
| Orkestrasi agent | LangGraph atau CrewAI |
| Smart account untuk pool settlement | ERC-4337 (scoped account) |
| Attestasi track record | EAS (Ethereum Attestation Service) |
| Sumber data kontrak | Indexer on-chain Base (baca bytecode/ABI, liquidity pool state, holder distribution) |

**Pembagian tanggung jawab (penting untuk defensibility di juri):**
- LLM bertugas mensintesis sinyal kualitatif dari kode kontrak menjadi probabilitas dan alasan — ini bagian yang tidak bisa digantikan rule engine sederhana karena setiap kontrak punya kombinasi fungsi yang berbeda-beda.
- Smart contract bertugas penuh untuk settlement, escrow dana pool, dan resolusi — LLM tidak pernah memegang atau memutuskan pergerakan dana secara langsung, keputusan final settlement murni berbasis event on-chain yang terverifikasi.

## 9. Data & Sumber yang Dibaca Agent

- Bytecode/ABI kontrak token baru (untuk deteksi fungsi berisiko).
- Status liquidity lock (dari pool DEX terkait, misal Uniswap/Aerodrome di Base).
- Distribusi holder teratas (dari indexer on-chain).

## 10. Metrik Sukses Produk

Lihat BRD bagian 10. Untuk MVP hackathon, metrik utama adalah kelancaran demo end-to-end dan kejelasan proposisi nilai bagi juri — bukan akurasi jangka panjang yang belum bisa diukur dalam waktu hackathon.

## 11. Roadmap Build (Indikatif — 2 Minggu Solo/Duo Dev)

**Minggu 1 — Agent & Odds Engine**
- Setup deteksi deploy token baru di Base.
- Implementasi pembacaan kontrak (fungsi berisiko, liquidity lock, holder concentration).
- Implementasi LLM scoring untuk menghasilkan probabilitas + alasan.

**Minggu 2 — Contract Pool, Resolusi, dan Demo**
- Smart contract pool YES/NO dan settlement logic.
- Integrasi oracle deteksi liquidity-pull untuk resolusi.
- Integrasi EAS untuk attestasi hasil.
- Siapkan 3 token uji untuk demo (1 aman, 1 mencurigakan, 1 rug historis terkonfirmasi) dan simulasikan liquidity-pull di depan juri.

## 12. Risiko Teknis & Asumsi

- **Asumsi:** data liquidity lock dan holder distribution tersedia dan bisa diakses secara real-time dari indexer yang dipakai.
- **Risiko:** token yang benar-benar baru mungkin belum punya cukup data on-chain (holder distribution, dsb) untuk skoring yang meyakinkan — perlu fallback logic untuk kasus data minim.
- **Risiko:** deteksi liquidity-pull sebagai satu-satunya sinyal resolusi bisa melewatkan bentuk rug-pull lain (misal mint tak terbatas tanpa menarik liquidity) — di MVP ini diterima sebagai batasan yang dinyatakan secara eksplisit, bukan diselesaikan penuh.

## 13. Out of Scope untuk MVP

- Multi-chain.
- Model odds dengan fine-tuning data historis besar.
- Mekanisme dispute/challenge terhadap hasil resolusi.
- Custodial wallet atau KYC.
- Kepatuhan regulasi penuh sebagai produk prediction market nyata (lihat BRD bagian 9).