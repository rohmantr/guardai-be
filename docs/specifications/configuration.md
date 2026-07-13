# Rug Radar — Configuration Reference

**Versi:** 1.0
**Tanggal:** 13 Juli 2026

---

## Application Configuration

```yaml
# config/default.yml
server:
  port: 3000
  host: "0.0.0.0"
  cors:
    origin: ["http://localhost:5173", "https://app.rugradar.xyz"]
    methods: ["GET", "POST"]
    credentials: true

rate_limiting:
  global:
    window_ms: 60000
    max_requests: 1000
  authenticated:
    window_ms: 60000
    max_requests: 100
  anonymous:
    window_ms: 60000
    max_requests: 10
  assessment:
    window_ms: 60000
    max_requests: 10

logging:
  level: "info"                  # debug | info | warn | error
  format: "json"                 # json | text
  output: "stdout"               # stdout | file
  file_path: "logs/app.log"      # if output=file
```

## Queue Configuration

```yaml
queue:
  provider: "redis"              # redis | rabbitmq
  redis:
    url: "redis://localhost:6379"
    prefix: "rugradar:queue:"
  rabbitmq:
    url: "amqp://localhost:5672"
    vhost: "/rugradar"
  
  # Per-queue settings
  queues:
    token_detection:
      concurrency: 2
      prefetch: 5
      retry_max: 3
      retry_delay_ms: [1000, 2000, 5000]
    assessment:
      concurrency: 3
      prefetch: 3
      retry_max: 2
      retry_delay_ms: [2000, 5000]
    settlement:
      concurrency: 1
      prefetch: 1
      retry_max: 3
      retry_delay_ms: [5000, 15000, 30000]
    attestation:
      concurrency: 2
      prefetch: 5
      retry_max: 2
      retry_delay_ms: [1000, 5000]

  dlq:
    retention_hours: 168         # 7 days
    alert_on_dlq: true
```

## RPC Configuration

```yaml
rpc:
  url: "https://mainnet.base.org"
  timeout_ms: 10000
  max_retries: 3
  retry_delay_ms: 1000
  rate_limit:
    requests_per_second: 10
    burst: 20
  
  # Fallback RPC (optional)
  fallback:
    enabled: false
    url: ""
```

## AI Provider Configuration

```yaml
ai:
  provider: "openai"             # openai | anthropic | gemini
  
  openai:
    api_key: "${LLM_API_KEY}"
    model: "gpt-4o"
    temperature: 0.0             # deterministic output
    max_tokens: 200
    timeout_ms: 15000
    max_retries: 2
    retry_delay_ms: 2000
  
  anthropic:
    api_key: ""
    model: "claude-sonnet-4-20250514"
    temperature: 0.0
    max_tokens: 200
    timeout_ms: 15000
  
  gemini:
    api_key: ""
    model: "gemini-2.0-flash"
    temperature: 0.0
    max_tokens: 200
    timeout_ms: 15000
```

## Timeout Settings

```yaml
timeouts:
  rpc_call_ms: 10000
  llm_request_ms: 15000
  db_query_ms: 5000
  http_request_ms: 30000
  health_check_ms: 3000
  
  # Graceful shutdown
  shutdown:
    grace_period_ms: 30000       # Wait for in-flight requests
    force_kill_ms: 5000          # After grace period
```

## Retry Policies

```yaml
retry:
  default:
    max_retries: 3
    strategy: "exponential"      # linear | exponential
    base_delay_ms: 1000
    max_delay_ms: 30000
  
  llm:
    max_retries: 2
    strategy: "linear"
    delays_ms: [2000, 5000]
  
  rpc:
    max_retries: 3
    strategy: "linear"
    delays_ms: [1000, 2000, 3000]
  
  db:
    max_retries: 3
    strategy: "exponential"
    base_delay_ms: 500
    max_delay_ms: 10000
```
