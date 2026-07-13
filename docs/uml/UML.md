# Rug Radar — UML Diagrams

**Versi:** 1.0
**Tanggal:** 13 Juli 2026
**Terkait:** Rug Radar BRD v1.0, Rug Radar PRD v1.0

Dokumen ini berisi empat diagram UML untuk Rug Radar: use case diagram, activity diagram, sequence diagram, dan class diagram. Semua diagram ditulis dalam sintaks Mermaid sehingga langsung ter-render di GitHub, VS Code, Typora, dan sebagian besar viewer markdown modern.

---

## 1. Use Case Diagram

Menunjukkan siapa berinteraksi dengan sistem dan untuk apa. Actor **Trader** memakai tiga use case utama (melihat skor risiko, membeli posisi prediksi, melihat riwayat akurasi). Actor **Oracle** hanya menyuplai satu data penting — event penarikan liquidity — yang dipakai sistem untuk resolusi otomatis; Oracle tidak pernah menyentuh dana atau keputusan.

*(Mermaid tidak punya tipe use case diagram native, sehingga direpresentasikan sebagai flowchart dengan subgraph sebagai batas sistem — pendekatan umum untuk dokumentasi use case dalam markdown.)*

```mermaid
flowchart LR
    Trader((Trader))
    Oracle((Oracle))
    subgraph SystemBoundary[Rug Radar]
        UC1([Lihat skor risiko token])
        UC2([Beli posisi prediksi YES/NO])
        UC3([Lihat riwayat akurasi agent])
        UC4([Sediakan data resolusi liquidity-pull])
    end
    Trader --- UC1
    Trader --- UC2
    Trader --- UC3
    Oracle --- UC4
```

---

## 2. Activity Diagram

Alur proses dari deteksi token baru sampai settlement. Ada dua titik keputusan: yang pertama menangani kasus token yang datanya belum cukup (fallback ke skor confidence rendah, tetap lanjut jalan agar tidak macet), yang kedua adalah keputusan settlement sebenarnya berdasarkan event on-chain — bukan opini agent.

```mermaid
flowchart TD
    Start([Mulai]) --> A[Deteksi & baca kontrak baru]
    A --> B{Data on-chain cukup?}
    B -- Tidak --> C[Tandai confidence rendah]
    C --> D[Generate skor probabilitas LLM]
    B -- Ya --> D
    D --> E[Buka pool prediksi YES/NO]
    E --> F{Liquidity ditarik dalam 24 jam?}
    F -- Ya --> G[Settle: posisi YES menang]
    F -- Tidak --> H[Settle: posisi NO menang]
    G --> I[Attest hasil ke EAS]
    H --> I
    I --> End([Selesai])
```

---

## 3. Sequence Diagram

Interaksi antar komponen dari waktu ke waktu. Agent tidak pernah mengeksekusi settlement secara langsung — dia hanya membaca dan mengumumkan (buka pool, attest hasil), sementara settlement adalah aksi internal Prediction Pool sendiri, dipicu murni oleh event dari Oracle.

```mermaid
sequenceDiagram
    participant User as Trader
    participant Agent as Rug Radar Agent
    participant Contract as Prediction Pool
    participant Oracle
    Contract-->>Agent: Token baru terdeploy
    Agent->>Contract: Baca bytecode & data on-chain
    Contract-->>Agent: Data kontrak
    Agent->>Agent: Generate skor probabilitas (LLM)
    Agent->>Contract: Buka pool prediksi YES/NO
    User->>Contract: Beli posisi YES/NO
    Oracle->>Contract: Event liquidity pull terdeteksi
    Contract->>Contract: Settle otomatis ke posisi menang
    Contract-->>User: Payout ke pemenang
    Agent->>Contract: Attest hasil ke EAS
```

---

## 4. Class Diagram

Struktur data yang mendasari sistem. `RiskAssessment` menjadi jembatan penting — mengikat pembacaan kontrak (`Token`) ke pembukaan pool (`PredictionPool`), sementara `ResolutionEvent` dan `Attestation` mencatat apa yang benar-benar terjadi setelahnya, bukan sekadar apa yang diprediksi agent.

```mermaid
classDiagram
    class Token {
        +string address
        +datetime deployedAt
        +bool liquidityLocked
        +float topHolderConcentration
    }
    class RiskAssessment {
        +string tokenAddress
        +float probability
        +string reasoning
    }
    class PredictionPool {
        +string poolId
        +float yesPoolAmount
        +float noPoolAmount
        +string status
    }
    class Position {
        +string poolId
        +string userAddress
        +string side
        +float amount
    }
    class ResolutionEvent {
        +string poolId
        +bool liquidityPulled
        +string winningSide
    }
    class Attestation {
        +string poolId
        +string verdict
        +string actualOutcome
    }
    class RugRadarAgent {
        +detectNewToken()
        +readContract()
        +generateScore()
        +openPool()
        +attestResult()
    }
    RugRadarAgent --> RiskAssessment : creates
    RiskAssessment --> Token : assesses
    RiskAssessment --> PredictionPool : initializes
    PredictionPool --> Position : has
    PredictionPool --> ResolutionEvent : resolved by
    ResolutionEvent --> Attestation : produces
    RugRadarAgent --> Attestation : submits
```