# Task-010: Assessment Module + AI Agent

**Prioritas:** P0
**Dependencies:** 009 (Token module)
**Module:** src/modules/assessment/ + agent/

---

## Objective

Buat module assessment yang mengintegrasikan LLM untuk risk scoring, plus AI Agent pipeline (data → prompt → LLM → validation → confidence).

## Specification

Lihat:
- `docs/architecture/ai-agent.md` — full pipeline
- `docs/prompts/risk-analysis.md` — system prompt
- `docs/prompts/output-schema.md` — JSON validation
- `docs/prompts/lifecycle.md` — retry + fallback
- `docs/architecture/api-spec.md` — assessment endpoints

### Components

#### Controller

```typescript
GET    /api/v1/assessments/:id           // Detail assessment
POST   /api/v1/assessments              // Trigger assessment manual
```

#### Service

```typescript
class AssessmentService {
  async assess(tokenAddress: string): Promise<Assessment>
  async get(id: string): Promise<Assessment>
  private async callLLM(data: ContractData): Promise<LLMOutput>
  private validateOutput(raw: string): LLMOutput
}
```

#### AI Agent Pipeline

```typescript
// agent/pipeline.ts
class RiskAgent {
  async run(tokenAddress: string): Promise<AssessmentResult> {
    const data = await this.collectData(tokenAddress);
    const prompt = this.buildPrompt(data);
    const raw = await this.callLLM(prompt);
    const validated = this.validate(raw);
    const confidence = this.calculateConfidence(data, validated);
    return { ...validated, confidence };
  }
}
```

#### Prompt Builder

```typescript
// agent/prompt.ts
function buildRiskAnalysisPrompt(data: ContractData): string {
  return `You are Rug Radar Risk Assessment Agent...
  ...${JSON.stringify(data)}
  Respond with ONLY valid JSON...`;
}
```

### LLM Client

```typescript
// agent/llm-client.ts
class LLMClient {
  async generate(prompt: string): Promise<string> {
    // POST https://api.openai.com/v1/chat/completions
    // With retry + timeout
  }
}
```

### Output Validator

```typescript
// agent/validator.ts
function validateLLMOutput(raw: string): LLMOutput {
  // Parse JSON
  // Validate against schema
  // Range check probability [0,1], confidence [0,1]
  // Reasoning length check
}
```

### Files to Create

| File | Path |
|------|------|
| Controller | `src/modules/assessment/controllers/assessment.controller.ts` |
| Service | `src/modules/assessment/services/assessment.service.ts` |
| Repository | `src/modules/assessment/repositories/assessment.repository.ts` |
| Entity | `src/modules/assessment/entities/risk-assessment.entity.ts` |
| Pipeline | `agent/pipeline.ts` |
| Prompt builder | `agent/prompt.ts` |
| LLM client | `agent/llm-client.ts` |
| Validator | `agent/validator.ts` |
| Unit test | `src/modules/assessment/assessment.service.spec.ts` |

### Acceptance Criteria

- [ ] `POST /api/v1/assessments` triggers full pipeline
- [ ] LLM output validated against schema
- [ ] Retry logic works (2 retries)
- [ ] Fallback probability = 0.5 when LLM fails
- [ ] Valid assessment saved to database
- [ ] `bun test` passes
