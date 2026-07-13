# Rug Radar — Task Backlog

**Versi:** 1.0
**Tanggal:** 13 Juli 2026

---

## Overview

Backlog seluruh implementasi Rug Radar untuk MVP (hackathon). Tiap task adalah unit kerja independen yang bisa dikerjakan sendiri.

Prioritas: **P0** = wajib untuk demo, **P1** = penting, **P2** = nice-to-have.

---

## Smart Contracts (Foundry)

| Task | Contract | Prioritas | Dependencies | Status |
|------|----------|-----------|--------------|--------|
| 001 | PredictionPool | P0 | — | ❌ |
| 002 | Treasury | P0 | — | ❌ |
| 003 | RiskRegistry | P0 | — | ❌ |
| 004 | OracleAdapter | P0 | — | ❌ |
| 005 | SettlementManager | P0 | 001, 004 | ❌ |
| 006 | AttestationAdapter | P1 | — | ❌ |
| 007 | Integration tests (contracts) | P0 | 001-006 | ❌ |

## Backend API (Bun/TypeScript)

| Task | Module | Prioritas | Dependencies | Status |
|------|--------|-----------|--------------|--------|
| 008 | Database schema + migrations | P0 | — | ❌ |
| 009 | Token module (detect + read) | P0 | 008 | ❌ |
| 010 | Assessment module + AI Agent | P0 | 009 | ❌ |
| 011 | Prediction module (pools + positions) | P0 | 010 | ❌ |
| 012 | Oracle + Attestation modules | P1 | 011 | ❌ |
| 013 | Workers (detector, settlement) | P0 | 011 | ❌ |

## Infrastructure

| Task | Component | Prioritas | Dependencies | Status |
|------|-----------|-----------|--------------|--------|
| 014 | Deployment scripts (forge) | P0 | 001-006 | ❌ |
| 015 | Docker Compose + CI/CD | P1 | — | ❌ |
| 016 | Frontend API integration | P0 | 011 | ❌ (guardai-fe) |

---

## Legend

| Status | Arti |
|--------|------|
| ❌ Belum dikerjakan | Task belum dimulai |
| 🔄 In progress | Sedang dikerjakan |
| ✅ Done | Selesai + test passing |

## Progress

```
Smart Contracts:   ░░░░░░░░░░ 0/7
Backend:           ░░░░░░░░░░ 0/6
Infrastructure:    ░░░░░░░░░░ 0/3

Total:             ░░░░░░░░░░ 0/16
```
