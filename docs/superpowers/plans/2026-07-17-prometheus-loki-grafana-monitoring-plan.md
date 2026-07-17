# Prometheus + Loki + Grafana Monitoring Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Instrument the Go backend with Prometheus metrics, configure Prometheus, Loki, Promtail, and Grafana with auto-provisioning configs, and update Docker Compose staging/production configurations.

**Architecture:** The Go backend exposes `/metrics`. Promtail tail-scrapes backend container stdout logs and pushes them to Loki. Grafana displays metrics and logs using pre-provisioned datasources.

**Tech Stack:** Go 1.25, Prometheus, Loki, Promtail, Grafana.

## Global Constraints
- Target folder for monitoring configs: `monitoring/`
- Target compose files: `docker-compose.dev.yml` and `docker-compose.prod.yml`
- Local compose file (`docker-compose.local.yml`) must not include monitoring services.
- Code Quality: `go fmt` and `go test` must pass clean.

---

### Task 1: Go Backend Instrumentation

**Files:**
- Create: `backend/middleware/metrics.go`
- Modify: `backend/main.go`

**Interfaces:**
- Produces: `middleware.PrometheusMetrics(next http.Handler) http.Handler`

- [ ] **Step 1: Get `github.com/prometheus/client_golang` dependency**
- [ ] **Step 2: Create `backend/middleware/metrics.go` defining the request counter and latency histogram**
- [ ] **Step 3: Update `backend/main.go` to register `/metrics` endpoint and wrap router with `PrometheusMetrics` middleware**

---

### Task 2: Monitoring Provisioning Configs

**Files:**
- Create: `monitoring/prometheus/prometheus.yml`
- Create: `monitoring/loki/loki-config.yml`
- Create: `monitoring/promtail/promtail-config.yml`
- Create: `monitoring/grafana/provisioning/datasources/datasources.yml`
- Create: `monitoring/grafana/provisioning/dashboards/dashboards.yml`
- Create: `monitoring/grafana/provisioning/dashboards/rugradar-dashboard.json`

- [ ] **Step 1: Write `prometheus.yml` configuring target scraping**
- [ ] **Step 2: Write `loki-config.yml` for local storage setup**
- [ ] **Step 3: Write `promtail-config.yml` configuring docker log discovery**
- [ ] **Step 4: Write Grafana datasources provisioning**
- [ ] **Step 5: Write Grafana dashboard provisioning and rugradar json dashboard**

---

### Task 3: Compose Updates & Testing

**Files:**
- Modify: `docker-compose.dev.yml`
- Modify: `docker-compose.prod.yml`

- [ ] **Step 1: Add `prometheus`, `loki`, `promtail`, and `grafana` services to `docker-compose.dev.yml`**
- [ ] **Step 2: Add matching services to `docker-compose.prod.yml`**
- [ ] **Step 3: Run Go tests to ensure instrumentation didn't break existing codebase**
