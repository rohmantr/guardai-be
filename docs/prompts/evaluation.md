# Rug Radar — Prompt Evaluation

**Versi:** 1.0.0
**Tanggal:** 13 Juli 2026

---

## Evaluation Criteria

| Criteria | Weight | Target | Metrik |
|----------|--------|--------|--------|
| **Accuracy** | 40% | > 80% | Precision, recall terhadap ground truth |
| **Consistency** | 25% | > 90% | Same input → same output (within ±0.05) |
| **Schema Compliance** | 20% | > 99% | % responses yang valid JSON sesuai schema |
| **Reasoning Quality** | 15% | > 85% | Reasoning relevan, faktual, tidak hallucinate |

## Accuracy Metrics

### Confusion Matrix

| | Actual Rug | Actual Safe |
|---|-----------|-------------|
| **Predicted Rug (p ≥ 0.6)** | TP | FP |
| **Predicted Safe (p ≤ 0.4)** | FN | TN |
| **Neutral (0.4 < p < 0.6)** | — | — |

### Target Metrics

| Metric | Target | Formula |
|--------|--------|---------|
| Precision | > 80% | TP / (TP + FP) |
| Recall | > 80% | TP / (TP + FN) |
| F1 Score | > 80% | 2 * (P * R) / (P + R) |
| AUC-ROC | > 0.85 | Area under ROC curve |

## Consistency Checks

### Test-Retest Reliability

Kirim input yang sama ke LLM sebanyak 5 kali dan ukur variance:

| Condition | Acceptable Variance |
|-----------|-------------------|
| Probability | ±0.05 |
| Confidence | ±0.05 |
| Risk factors | Same set |
| Reasoning | Different wording, same facts |

### Parallel Form Reliability

Kirim dua varian prompt yang sama secara semantik dan bandingkan output — harus menghasilkan probability dalam ±0.10.

## Regression Testing

Setiap prompt version bump (minor or major) harus melewati regression test:

```typescript
const testCases = [
  { input: safeTokenData, expectedRange: [0.0, 0.3] },
  { input: rugTokenData, expectedRange: [0.7, 1.0] },
  { input: partialData, expectedConfidence: [0.0, 0.4] },
  { input: noData, expectedProbability: 0.5 },
];

testCases.forEach(({ input, expectedRange, expectedConfidence }) => {
  const output = await runLLM(input);
  assert(output.probability >= expectedRange[0] && output.probability <= expectedRange[1]);
  if (expectedConfidence) {
    assert(output.confidence >= expectedConfidence[0] && output.confidence <= expectedConfidence[1]);
  }
});
```

Regression test dijalankan di CI sebelum deploy prompt baru.

## Benchmark Examples

| Scenario | Input Signature | Expected Probability | Expected Confidence |
|----------|----------------|---------------------|-------------------|
| Liquidity locked, no mint, diverse holders | clean contract | 0.0 - 0.2 | 0.8 - 1.0 |
| Unlimited mint + no lock + 90% top holder | obvious rug | 0.8 - 1.0 | 0.8 - 1.0 |
| Only address known | minimal data | 0.4 - 0.6 | 0.0 - 0.3 |
| Honeypot with tax | trap token | 0.7 - 0.9 | 0.7 - 0.9 |
| Proxy + ownership renounced | intermediate | 0.3 - 0.6 | 0.5 - 0.7 |

Benchmark di-run setiap minggu dan hasilnya dicatat untuk monitoring drift.
