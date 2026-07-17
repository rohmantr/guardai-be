# Specification: Prometheus, Loki, and Grafana Monitoring for Staging & Production

This specification details the monitoring stack (Prometheus, Loki, Promtail, Grafana) setup for Rug Radar's staging and production environments, including metric instrumentation in the Go backend.

## 1. Metrics Instrumentation in Go Backend

Using `github.com/prometheus/client_golang`, the backend exposes a HTTP `/metrics` endpoint.

### Custom Metrics
- `http_requests_total (Counter)`: Track HTTP request counts with labels: `path`, `method`, `status`.
- `http_request_duration_seconds (Histogram)`: Track HTTP response latency with labels: `path`, `method`.

## 2. Log Pipeline (Loki + Promtail)

- **Go Backend**: Output structured JSON logs to stdout.
- **Promtail**: Scrape logs of the backend container via Docker volume sockets and forward to Loki.
- **Loki**: Store log streams and expose query API for Grafana.

## 3. Provisioning Grafana

Grafana configuration is provisioned automatically with:
- **Datasources**:
  - `Prometheus` (default metrics collector)
  - `Loki` (default logs collector)
- **Dashboards**:
  - A preconfigured dashboard showing HTTP latency, request count, error rate, system metrics, and live log stream search.

## 4. Docker Compose Configurations

The monitoring services are added to:
- `docker-compose.dev.yml` (Staging)
- `docker-compose.prod.yml` (Production)

Local environment (`docker-compose.local.yml`) remains lightweight and clean.
