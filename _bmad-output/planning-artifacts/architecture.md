---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
status: 'complete'
completedAt: '2026-03-31'
lastStep: 8
inputDocuments: ['prd.md', 'product-brief-homelab.md']
workflowType: 'architecture'
project_name: 'homelab'
user_name: 'Ducdo'
date: '2026-03-30'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements:**
47 FRs spanning 9 domains, plus 5 vision-phase requirements. The core architectural challenge is not any single domain but the **integration layer** connecting them — every pipeline follows the same pattern: ingest → AI process → store/notify. The architecture must make this pattern cheap to implement repeatedly.

Key FR clusters that drive architecture:
- **FR9-13 (AI Inference):** Demand a shared AI routing layer with fallback logic
- **FR18-22 + FR23-29 (Pipelines):** Two major Go services (trend analysis, log monitoring) that share common patterns — scheduled execution, AI processing, email output, Qdrant indexing
- **FR30-33 (Knowledge):** Qdrant as the shared knowledge store creates a convergence point — embedding format and metadata schema must be standardized early
- **FR37-40 (Observability):** Uniform `/health` and `/status` contracts across all Go services, structured JSON logging to Loki

**Non-Functional Requirements:**
23 NFRs across performance, security, reliability, integration, and maintainability. The most architecturally significant:
- **NFR5:** 32GB RAM budget with per-service Docker memory limits — requires explicit memory allocation planning
- **NFR6:** Tailscale-only access (no public ports except Caddy webhooks) — simplifies security model significantly
- **NFR11-15:** 24/7 uptime with graceful degradation and no cascading failures — each service must be independently deployable and restartable
- **NFR20:** <2 hours/week maintenance — drives toward convention over configuration, declarative infrastructure, and minimal operational surface

**Scale & Complexity:**

- Primary domain: Infrastructure platform / backend services
- Complexity level: Medium
- Estimated architectural components: ~12-15 (9 off-the-shelf services + 3-4 custom Go services + shared internal package)

### Technical Constraints & Dependencies

- **Hardware:** Single node — Ryzen 9950X, RTX 5060 16GB, 32GB RAM, 1TB NVMe + recommended 2nd NVMe for data
- **OS:** Fedora bare metal (no hypervisor) — GPU access is direct, no passthrough complexity
- **Runtime:** Docker Compose exclusively — no Kubernetes, no Swarm
- **Language:** Go for all custom services — single-binary Docker images
- **GPU:** Single-inference bottleneck (one Ollama request at a time) — pipelines must tolerate queuing
- **Network:** Tailscale VPN for all remote access; Caddy for internal routing + TLS
- **External dependencies:** Claude API, HN/GitHub/Reddit APIs, Railway/Sentry/GCP log sources, SMTP provider

### Cross-Cutting Concerns Identified

1. **AI Routing & Fallback** — shared logic for Ollama vs Claude selection and automatic degradation
2. **Structured Logging** — all services output JSON to stdout, consumed by Loki via Docker log driver
3. **Health & Status Contracts** — `/health` and `/status` endpoints on every Go service
4. **Qdrant Knowledge Schema** — consistent embedding format, metadata structure, and temporal indexing across all producers
5. **Email Delivery** — single SMTP service consumed by all pipelines
6. **Memory Budget** — Docker memory limits enforced per container within 32GB total
7. **Graceful Degradation** — each service must handle missing dependencies without crashing
8. **Configuration Management** — Docker Compose + environment variables + mounted config files

## Starter Template Evaluation

### Primary Technology Domain

Infrastructure platform — Go monorepo + Docker Compose service orchestration. No traditional starter template applies; the foundation is a custom project structure.

### Starter Options Considered

No off-the-shelf starter template fits this project. This is an infrastructure platform composed of off-the-shelf Docker services plus custom Go glue services. The "starter" is a well-structured repo layout with conventions.

### Selected Approach: Go Monorepo with Docker Compose

**Rationale:** Go's stdlib (1.22+ routing, `log/slog`) covers all service needs without external frameworks. Single module with shared `internal/` package ensures consistency across services while keeping dependency management simple. Docker Compose at repo root is the primary interface for the entire system.

**Project Structure:**

```
homelab/
├── cmd/
│   ├── hn-digest/              # Phase 3 walking skeleton
│   │   ├── main.go
│   │   └── Dockerfile
│   ├── trend-analyzer/         # Phase 4
│   │   ├── main.go
│   │   └── Dockerfile
│   └── log-monitor/            # Phase 5
│       ├── main.go
│       └── Dockerfile
├── internal/                   # Grows incrementally with services
│   ├── ai/                     # Phase 3: Ollama + Claude routing
│   │   ├── client.go           # InferenceClient interface
│   │   ├── ollama.go
│   │   ├── claude.go
│   │   ├── router.go           # Selection, fallback, retry logic
│   │   └── router_test.go
│   └── email/                  # Phase 3: SMTP client
│       └── smtp.go
├── configs/
│   ├── caddy/
│   │   └── Caddyfile
│   ├── grafana/
│   │   └── dashboards/
│   ├── loki/
│   │   └── config.yaml
│   └── n8n/                    # Workflow exports/backups
├── scripts/
│   └── init-host.sh            # First-boot: create dirs, copy .env.example → .env
├── docker-compose.yml          # All service definitions — repo entry point
├── .env.example                # Template for secrets (committed)
├── .env                        # Actual secrets (git-ignored)
├── go.mod
├── go.sum
└── README.md
```

**Architectural Decisions Established:**

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Go version | 1.26 (latest stable) | Green Tea GC by default, 30% cgo overhead reduction |
| HTTP router | `net/http` stdlib (1.22+ pattern matching) | Zero dependencies, sufficient for `/health`, `/status`, webhooks |
| Config loading | `os.Getenv` stdlib | Simple env var reads — no complex config trees |
| Logging | `log/slog` stdlib | Structured JSON output, Loki-compatible, zero dependencies |
| Module structure | Single module (`github.com/ducdo/homelab`) | Shared `internal/`, single `go.mod` |
| Compose location | Repo root | Primary project interface — no `-f` flag needed |
| Compose profiles | None | Explicit service names for partial bring-up; profiles solve a multi-team problem that doesn't exist here |
| Dockerfile strategy | Per-service in `cmd/<service>/` | Each stays simple; no conditional multi-service Dockerfile |
| Build pattern | Multi-stage: `golang:1.26` → `gcr.io/distroless/static` | Minimal attack surface, tiny runtime images |
| `internal/` growth | Incremental — `ai/` and `email/` for Phase 3 | Add packages as services demand them, not speculatively |

**Note:** Project initialization and base structure setup should be the first implementation story.

## Core Architectural Decisions

### Decision Priority Analysis

**Critical Decisions (Block Implementation):**
- Docker networking: single shared `homelab` bridge network
- Secret management: `.env` file (git-ignored), `.env.example` committed as template
- Volume strategy: bind mounts to `/data/homelab/<service>/`
- Memory budget: explicit `mem_limit` per container within 32GB
- Pipeline state: in-memory + JSON file on disk per service
- AI router: explicit `InferenceClient` interface for testability and fallback logic
- Host initialization: `scripts/init-host.sh` for first-boot setup

**Important Decisions (Shape Architecture):**
- Error handling: retry with exponential backoff + log and continue
- Scheduling: `robfig/cron` library for cron-expression-based scheduling (no clock drift)
- Inter-service auth: none — trust Docker network
- Backup scope: config + critical data only (skip logs and vectors)
- Embedding model: `nomic-embed-text` (768 dimensions, lightweight) — standard locked for Phase 6

**Deferred Decisions (Post-MVP):**
- Webhook authentication for log drains (Phase 5)
- RAG query interface design (Phase 6)
- Digest/alert content persistence beyond email (Phase 6 — RAG indexing)

### Data Architecture

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Pipeline state storage | In-memory + JSON file on disk | Survives restarts via Docker volume, zero infrastructure, Loki has historical data as backup |
| Embedding model | `nomic-embed-text` (768 dims) | Lightweight, good quality, runs efficiently on RTX 5060. Locks vector dimensions across all producers |
| Digest/alert persistence | Email only until Phase 6 | No premature storage — RAG layer will index all outputs when built |
| Shared database | None | Each service owns its own state. Qdrant is the only shared data store (via API) |

### Authentication & Security

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Secret storage | Docker Compose `.env` file (git-ignored), `.env.example` committed | Simple, sufficient for solo dev, loaded via `env_file:` directive |
| Webhook auth (log drains) | Deferred to Phase 5 | No log ingestion until Phase 5 — decide when building |
| Inter-service auth | None — trust Docker network | All services internal, Tailscale-only external access, no threat model justification for internal auth |
| External access | Tailscale VPN only | No public ports except Caddy webhook endpoints (Phase 5+) |

### API & Communication Patterns

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Docker networking | Single shared `homelab` bridge network | All services reference each other by service name. Segmentation unjustified for single-node solo setup |
| Service communication | HTTP/REST + webhooks | Loosely coupled, simple, debuggable. Each service is independently deployable |
| Error handling | Retry with exponential backoff + log and continue | Failed items don't block pipelines. Errors logged to Loki, surfaced on `/status`. NFR16 compliance |
| Scheduled execution | `robfig/cron` library (in-process) | Cron expressions for precise scheduling (e.g., "0 2 * * *"), no clock drift from container start time. Service stays running, exposes `/health` and `/status` |
| AI routing | `InferenceClient` interface with Ollama + Claude implementations | Testable via mock injection, clean fallback logic, retry isolated in `router.go`. The load-bearing wall of the system — worth getting right early |

### Frontend Architecture

Not applicable — email is the delivery surface for all user-facing output. n8n and Grafana provide their own web UIs. No custom frontend for MVP through Phase 5.

### Infrastructure & Deployment

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Volume strategy | Bind mounts to `/data/homelab/<service>/` | Visible, easy to reason about disk usage, trivial to point at second NVMe |
| Host initialization | `scripts/init-host.sh` | Creates bind mount directories, copies `.env.example` → `.env`, sets permissions. One command from fresh Fedora to ready-to-run |
| Backup scope | Config + critical data only | Gitea repos, n8n workflows, Grafana dashboards, service configs, Qdrant collections. Skip logs and vectors (rebuildable) |
| Backup tool | Restic to off-machine storage | Encrypted at rest (NFR8), daily with 7-day retention (NFR13) |
| Memory budget | Explicit `mem_limit` per container | See allocation table below |

**Memory Allocation (32GB total):**

| Service | Allocation | Notes |
|---------|-----------|-------|
| Ollama | 16GB | Accommodates model hot-swaps without OOM-kill |
| Qdrant | 2GB | Vector index in memory |
| Grafana | 512MB | Dashboards + queries |
| Loki | 1GB | Log ingestion + indexing |
| n8n | 1GB | Workflow execution |
| Gitea | 512MB | Light git hosting |
| Caddy | 256MB | Reverse proxy |
| Custom Go services (each) | 256MB | Lightweight binaries |
| OS + Docker overhead | ~4GB | Fedora + Docker daemon |
| **Headroom** | **~5GB** | Buffer for spikes |

### Decision Impact Analysis

**Implementation Sequence:**
1. `scripts/init-host.sh` + `.env.example` (host preparation)
2. Docker Compose + single `homelab` network + Caddy (foundation)
3. `.env` file with initial secrets (Claude API key, SMTP creds)
4. Bind mount directories on host (`/data/homelab/<service>/`)
5. Off-the-shelf services (Ollama, Grafana, Loki, Qdrant, Gitea, n8n, Tailscale)
6. Restic backup configuration
7. First Go service (hn-digest walking skeleton) with `internal/ai/` (interface-driven) and `internal/email/`

**Cross-Component Dependencies:**
- All Go services depend on the `homelab` Docker network and Ollama being available
- `InferenceClient` interface is the shared contract — all pipeline services import `internal/ai`
- Memory budget is a hard constraint — adding services requires re-evaluating allocations
- Bind mount paths created by `scripts/init-host.sh` — must run before first `docker compose up`
- `.env` file must be populated from `.env.example` — never committed to git

## Implementation Patterns & Consistency Rules

### Pattern Categories Defined

**Critical Conflict Points Identified:** 5 areas where AI agents could make different choices — Go code conventions, API response formats, logging standards, test organization, and Docker service naming.

### Go Code Conventions

| Pattern | Rule | Example |
|---------|------|---------|
| File naming | `snake_case.go` | `ollama_client.go`, `router_test.go` |
| Package naming | Short, lowercase, no underscores | `ai`, `email`, `health`, `qdrant` |
| Error wrapping | Always wrap with `fmt.Errorf` context | `fmt.Errorf("sending digest: %w", err)` |
| Constructors | `New` for single-type packages, `NewXxx` for multi-type | `ai.NewOllamaClient()`, `email.New()` |
| Exported types | One primary type per package where possible | `ai.InferenceClient`, `email.Client` |
| Config pattern | Struct passed to constructor | `NewOllamaClient(cfg OllamaConfig)` |

### API Response Formats

All Go services expose identical endpoint formats for Grafana compatibility:

**`GET /health`**
```json
{"status": "ok"}
```
```json
{"status": "degraded", "reason": "ollama unreachable"}
```

**`GET /status`**
```json
{
  "service": "hn-digest",
  "last_run": "2026-03-31T02:00:00Z",
  "last_result": "success",
  "error": null,
  "runs_today": 1,
  "next_run": "2026-04-01T02:00:00Z"
}
```

**Format Rules:**
- JSON field naming: `snake_case` (via Go struct tags)
- Dates: ISO 8601 strings (`time.RFC3339`)
- Null for absent values (not empty string or zero)
- HTTP status codes: `200` for healthy, `503` for degraded/unhealthy

### Logging Conventions

All services use `log/slog` with JSON handler to stdout.

| Rule | Standard | Example |
|------|----------|---------|
| Key naming | `snake_case` | `service_name`, `pipeline_run_id` |
| Required keys | `service`, `component` on every line | `"service": "hn-digest", "component": "ai"` |
| `INFO` | Pipeline start/complete, successful operations | `"msg": "digest pipeline complete", "items": 10` |
| `WARN` | Retries, degraded operation, fallback triggered | `"msg": "claude unavailable, falling back to ollama"` |
| `ERROR` | Failures that affect output quality or delivery | `"msg": "email delivery failed", "error": "..."` |
| Context | Always include operation context | `slog.With("pipeline", "hn-digest", "run_id", runID)` |

### Retry Pattern

Standardized retry constants defined in `internal/ai/router.go` — single source of truth:

| Parameter | Value |
|-----------|-------|
| Max attempts | 3 |
| Base delay | 1 second |
| Max delay | 30 seconds |
| Strategy | Exponential with jitter |

All pipeline retry logic uses these constants. No per-service overrides without explicit justification.

### Graceful Shutdown Pattern

Every `cmd/<service>/main.go` follows this skeleton:

```go
ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGTERM, syscall.SIGINT)
defer stop()
// start HTTP server, start cron scheduler
<-ctx.Done()
// shutdown with timeout (e.g., 10s)
```

No alternative shutdown patterns (`os.Signal` channels, bare `select` blocks). One pattern, every service.

### InferenceClient Interface Contract

Locked interface signature in `internal/ai/client.go`:

```go
type InferenceClient interface {
    Complete(ctx context.Context, prompt string, opts ...Option) (string, error)
}
```

The `opts ...Option` pattern provides extensibility (model selection, temperature) without breaking the interface. All pipeline services import and depend on this interface.

### Test Organization

| Pattern | Rule |
|---------|------|
| Unit tests | Co-located: `router_test.go` beside `router.go` |
| Test style | Table-driven tests as default pattern |
| Integration tests | `cmd/<service>/integration_test.go` with `//go:build integration` tag |
| Mock pattern | Interface-based — inject mock implementations |
| Test helpers | `internal/ai/aitest/mock.go` for shared mock `InferenceClient` |
| Test naming | `TestFunctionName_scenario` (e.g., `TestRouter_fallbackOnClaudeTimeout`) |

### Config Loading Pattern

Every service has `cmd/<service>/config.go` with identical structure:

```go
type Config struct {
    OllamaURL    string // OLLAMA_URL
    SMTPHost     string // SMTP_HOST
    CronSchedule string // CRON_SCHEDULE
}

func LoadConfig() Config {
    return Config{
        OllamaURL:    getEnv("OLLAMA_URL", "http://ollama:11434"),
        CronSchedule: getEnv("CRON_SCHEDULE", "0 2 * * *"),
    }
}

func getEnv(key, fallback string) string {
    if v := os.Getenv(key); v != "" {
        return v
    }
    return fallback
}
```

Same pattern, same helper, different env vars per service.

### Docker Compose Service Naming

| Type | Convention | Examples |
|------|-----------|----------|
| Off-the-shelf | Canonical lowercase name | `ollama`, `grafana`, `loki`, `qdrant`, `gitea`, `caddy`, `n8n` |
| Custom Go services | Lowercase, hyphenated | `hn-digest`, `trend-analyzer`, `log-monitor` |
| Network | Single network, project name | `homelab` |
| Volumes (bind mounts) | `/data/homelab/<service>/` | `/data/homelab/qdrant/`, `/data/homelab/grafana/` |

### Enforcement Guidelines

**All AI Agents MUST:**
- Wrap every returned error with `fmt.Errorf` operation context
- Use the exact `/health` and `/status` JSON response structures defined above
- Include `service` and `component` keys in every `slog` call
- Write table-driven tests for all non-trivial functions
- Use `snake_case` for all JSON field tags and log keys
- Implement graceful shutdown via `signal.NotifyContext` in every `main.go`
- Use the `InferenceClient` interface — never call Ollama/Claude directly
- Follow the `Config` struct + `LoadConfig()` + `getEnv()` pattern for configuration
- Use the standard retry constants from `router.go`
- Include `restart: unless-stopped` on every service in `docker-compose.yml` (NFR12)

**Anti-Patterns (Never Do):**
- Bare `return err` without wrapping context
- Custom `/health` response formats that differ from the standard
- `fmt.Println` or `log.Println` instead of `slog`
- Tests that depend on external services without `//go:build integration` tag
- `camelCase` JSON fields (e.g., `lastRun` instead of `last_run`)
- Custom shutdown logic or `os.Signal` channels instead of `signal.NotifyContext`
- Per-service retry constants that diverge from the standard
- Config loading via `viper`, `envconfig`, or other libraries — stdlib `os.Getenv` only

## Project Structure & Boundaries

### Complete Project Directory Structure (Target State)

```
homelab/
├── cmd/
│   ├── hn-digest/                      # Phase 3: Walking skeleton
│   │   ├── main.go                     # Entry point, slog init, graceful shutdown, cron
│   │   ├── config.go                   # Config struct + LoadConfig() + getEnv()
│   │   ├── Dockerfile                  # Multi-stage: golang:1.26 → distroless
│   │   └── integration_test.go         # //go:build integration
│   ├── trend-analyzer/                 # Phase 4: Full idea generation pipeline
│   │   ├── main.go
│   │   ├── config.go
│   │   ├── Dockerfile
│   │   └── integration_test.go
│   └── log-monitor/                    # Phase 5: Production log triage
│       ├── main.go
│       ├── config.go
│       ├── Dockerfile
│       └── integration_test.go
├── internal/
│   ├── ai/                             # Phase 3: AI routing layer
│   │   ├── client.go                   # InferenceClient interface
│   │   ├── ollama.go                   # OllamaClient implementation
│   │   ├── claude.go                   # ClaudeClient implementation
│   │   ├── router.go                   # Selection, fallback, retry (standard constants)
│   │   ├── router_test.go
│   │   └── aitest/
│   │       └── mock.go                 # Shared mock InferenceClient for all tests
│   ├── email/                          # Phase 3: SMTP delivery + disk-backed queue
│   │   ├── smtp.go                     # Email client with queue-on-failure
│   │   ├── queue.go                    # Disk-backed retry queue (72-hour TTL)
│   │   └── smtp_test.go               # Send, queue-on-failure, retry, TTL-discard
│   ├── health/                         # Phase 3: Shared /health + /status handlers
│   │   ├── handler.go                  # Standard JSON response formats
│   │   └── handler_test.go
│   └── qdrant/                         # Phase 6: Vector store client
│       ├── client.go
│       └── client_test.go
├── configs/
│   ├── caddy/
│   │   └── Caddyfile                   # Reverse proxy routes, TLS config
│   ├── grafana/
│   │   ├── provisioning/
│   │   │   ├── datasources/
│   │   │   │   └── loki.yaml           # Auto-provision Loki datasource
│   │   │   └── dashboards/
│   │   │       └── dashboards.yaml     # Auto-provision dashboard directory
│   │   └── dashboards/
│   │       ├── system-overview.json    # CPU, RAM, GPU, disk
│   │       ├── container-health.json   # Docker container status
│   │       └── pipeline-health.json    # Go service /status aggregation
│   ├── loki/
│   │   └── config.yaml                 # Loki ingestion + retention config
│   └── n8n/                            # Workflow exports/backups
├── docs/
│   └── runbooks/                       # Phase 1-2: Operational runbooks
│       └── new-pipeline.md             # 6-step procedure for adding a new pipeline service
├── scripts/
│   └── init-host.sh                    # First-boot: create /data/homelab/*, copy .env
├── docker-compose.yml                  # All service definitions + Loki log driver config
├── .env.example                        # Template for secrets (committed)
├── .env                                # Actual secrets (git-ignored)
├── .gitignore
├── go.mod
├── go.sum
└── README.md
```

### Phase Build Order

Agents MUST only create files and directories for the phase being implemented. Do not scaffold future phases.

| Phase | Create | Notes |
|-------|--------|-------|
| **1-2: Foundation** | `docker-compose.yml`, `configs/`, `scripts/init-host.sh`, `.env.example`, `.gitignore`, `go.mod`, `README.md`, `docs/runbooks/` | Infrastructure + runbooks — no Go services yet |
| **3: Walking Skeleton** | `cmd/hn-digest/`, `internal/ai/`, `internal/email/`, `internal/health/` | First Go service + all shared packages it needs |
| **4: Trend Analysis** | `cmd/trend-analyzer/` | Reuses existing `internal/` packages |
| **5: Log Monitoring** | `cmd/log-monitor/` | Reuses existing `internal/` packages |
| **6: Knowledge Layer** | `internal/qdrant/` | New shared package for vector store access |

### Log Collection Strategy

Docker logs are shipped to Loki via the **Loki Docker log driver plugin** — no Promtail container required. Configured per-service in `docker-compose.yml`:

```yaml
services:
  hn-digest:
    logging:
      driver: loki
      options:
        loki-url: "http://localhost:3100/loki/api/v1/push"
        loki-batch-size: "400"
```

This eliminates an extra container and its memory footprint. If non-Docker log sources are needed in the future (e.g., host system logs), Promtail can be added at that time.

### slog Initialization

No `internal/logging/` package. Each `main.go` initializes structured logging inline:

```go
logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
slog.SetDefault(logger.With("service", "hn-digest"))
```

Two lines per service. Consistent because the pattern is specified, not because it's abstracted.

### .gitignore Contents

```
.env
/data/
.idea/
.vscode/
*.swp
```

### Architectural Boundaries

**Service Boundaries:**

| Service | Owns | Communicates With | Data Store |
|---------|------|-------------------|------------|
| hn-digest | HN scraping, summarization, digest formatting | Ollama, Claude (via `internal/ai`), SMTP (via `internal/email`) | JSON state file in `/data/homelab/hn-digest/` |
| trend-analyzer | Multi-source scraping, clustering, scoring | Ollama, Claude, SMTP, Qdrant (Phase 6) | JSON state file in `/data/homelab/trend-analyzer/` |
| log-monitor | Log ingestion, anomaly detection, alerting | Ollama, Claude, SMTP, Qdrant (Phase 6) | JSON state file in `/data/homelab/log-monitor/` |
| Ollama | Model loading, inference | GPU (direct) | Models in `/data/homelab/ollama/` |
| Qdrant | Vector storage, search | None (serves API) | Collections in `/data/homelab/qdrant/` |
| n8n | Simple automations, prototyping | Ollama, Claude, SMTP, any HTTP service | Workflows in `/data/homelab/n8n/` |

**`internal/` Package Boundaries:**

| Package | Responsibility | Imported By | Phase |
|---------|---------------|-------------|-------|
| `internal/ai` | AI routing, fallback, retry — `InferenceClient` contract | All `cmd/` services | 3 |
| `internal/ai/aitest` | Mock `InferenceClient` for testing | All `cmd/` test files | 3 |
| `internal/email` | SMTP delivery + disk-backed queue with 72-hour TTL (FR36) | All `cmd/` services | 3 |
| `internal/health` | `/health` and `/status` HTTP handlers | All `cmd/` services | 3 |
| `internal/qdrant` | Qdrant vector store client | Phase 6+ services | 6 |

**Data Flow — Pipeline Pattern:**
```
External Source → cmd/<service> → internal/ai (Ollama/Claude) → internal/email (SMTP)
                                         ↓ (Phase 6+)
                                  internal/qdrant (embeddings → Qdrant)
```

### Requirements to Structure Mapping

**FR Category Mapping:**

| FR Category | Directory | Key Files | Phase |
|-------------|-----------|-----------|-------|
| FR1-8 (Infrastructure) | `docker-compose.yml`, `configs/`, `scripts/` | Caddy, Grafana, Loki config files | 1-2 |
| FR9-13 (AI Inference) | `internal/ai/` | `client.go`, `ollama.go`, `claude.go`, `router.go` | 3 |
| FR14-17 (Workflow Automation) | `configs/n8n/` | n8n workflow exports | 3 |
| FR18-22 (Trend Analysis) | `cmd/hn-digest/`, `cmd/trend-analyzer/` | `main.go`, `config.go` | 3-4 |
| FR23-29 (Log Monitoring) | `cmd/log-monitor/` | `main.go`, `config.go` | 5 |
| FR30-33 (Knowledge) | `internal/qdrant/` | `client.go` | 6 |
| FR34-36 (Notifications) | `internal/email/` | `smtp.go` | 3 |
| FR37-40 (Observability) | `internal/health/`, `configs/grafana/` | `handler.go`, dashboard JSONs | 3 |
| FR41-42 (Degraded Mode) | `internal/ai/router.go` | Fallback logic | 3 |

### Integration Points

**Internal Communication (Docker network):**

| From | To | Protocol | Purpose |
|------|----|----------|---------|
| Go services | `ollama:11434` | HTTP REST | AI inference |
| Go services | `qdrant:6333` | HTTP REST | Vector search (Phase 6) |
| Go services | SMTP provider | SMTP/TLS | Email delivery |
| n8n | `ollama:11434` | HTTP REST | AI in workflows |
| n8n | Go services | HTTP webhook | Trigger pipelines |
| Loki log driver | `loki:3100` | HTTP | Log ingestion |
| Grafana | `loki:3100` | HTTP | Log queries |
| Grafana | Go services `/status` | HTTP | Pipeline health dashboards |
| Caddy | All web UIs | HTTP | Reverse proxy |

**External Integrations (internet-dependent):**

| Service | External Target | Protocol | Phase |
|---------|----------------|----------|-------|
| hn-digest | Hacker News API | HTTPS | 3 |
| trend-analyzer | HN, GitHub, Reddit APIs | HTTPS | 4 |
| log-monitor | Railway log drains | HTTPS webhook (inbound) | 5 |
| log-monitor | Sentry webhooks | HTTPS webhook (inbound) | 5 |
| log-monitor | GCP Cloud Logging | HTTPS | 5 |
| Go services | Claude API | HTTPS | 3+ |
| Restic | Off-machine backup target | HTTPS/SFTP | 2 |

### Development Workflow

**Local Development:**
1. Run `scripts/init-host.sh` (first time only)
2. Populate `.env` from `.env.example`
3. `docker compose up -d` — starts all infrastructure
4. Develop Go services locally with `go run cmd/<service>/main.go` (pointing env vars at Docker services)
5. Build and test: `go test ./...` (unit), `go test -tags=integration ./...` (integration, needs Docker services running)
6. Build Docker image: `docker compose build <service>`

**Deployment:**
- `docker compose up -d` — runs everything including custom Go services
- Update a single service: `docker compose up -d --build <service>`
- No CI/CD pipeline until Phase 8 — manual `docker compose` commands

### Email Queue Design (FR36)

`internal/email/` must implement a disk-backed queue for resilient delivery:

- On successful SMTP send: deliver immediately, no queue involvement
- On SMTP failure: serialize email to JSON file in `/data/homelab/<service>/email-queue/`
- Retry timer: attempt redelivery of queued emails every 5 minutes
- TTL: discard queued emails older than 72 hours to prevent alert flooding on reconnection
- Queue file format: one JSON file per email, filename includes timestamp for TTL calculation

**Required test cases for `internal/email/`:**

| Case | Behavior |
|------|----------|
| Successful send | Email delivered via SMTP, no queue file created |
| SMTP failure | Email serialized to disk queue |
| Retry delivers | Queued email sent on next retry cycle |
| TTL discard | Email older than 72 hours deleted without sending |

### New Pipeline Runbook (NFR21)

To add a new pipeline service (target: <1 hour for simple cases):

1. `mkdir cmd/<name>/` — create service directory
2. Copy `main.go`, `config.go`, `Dockerfile`, `integration_test.go` from an existing service (e.g., `cmd/hn-digest/`)
3. Update in `config.go`: service-specific env vars and defaults. Update in `main.go`: service name in slog init, cron schedule, pipeline logic
4. Add service block to `docker-compose.yml`: image, build context, `mem_limit: 256m`, `restart: unless-stopped`, logging driver, network, env_file, bind mount volume
5. Add bind mount directory to `scripts/init-host.sh`: `/data/homelab/<name>/`
6. Run `go test ./cmd/<name>/...` and `docker compose build <name>`

## Architecture Validation Results

### Coherence Validation ✅

**Decision Compatibility:** All decisions are internally consistent. Go 1.26 stdlib + `robfig/cron` — no conflicts. Docker Compose + single network + bind mounts — all aligned. `InferenceClient` interface + retry constants + graceful shutdown — coherent service pattern. Loki Docker log driver + `slog` JSON output — compatible pipeline. Memory budget sums to ~27GB with ~5GB headroom.

**Pattern Consistency:** All patterns reinforce each other. `snake_case` everywhere. Config pattern consistent across services. `/health` and `/status` formats identical. Error wrapping + `slog` context keys + retry logging — complete observability chain.

**Structure Alignment:** Project structure maps cleanly to all decisions. Phase Build Order prevents premature scaffolding. `internal/` packages match cross-cutting concerns 1:1. Each `cmd/` service follows identical skeleton.

### Requirements Coverage Validation ✅

**Functional Requirements:** All 42 core FRs (FR1-42) have explicit architectural support mapped to specific directories and files. 5 vision-phase FRs (FR43-47) are deferred by design and not architecturally blocked.

**Non-Functional Requirements:** All 23 NFRs covered:
- NFR5 (32GB budget): Memory allocation table validated — sums correctly with 5GB headroom
- NFR12 (Auto-restart): `restart: unless-stopped` added to enforcement guidelines
- NFR21 (New pipeline <1hr): 6-step runbook documented in `docs/runbooks/new-pipeline.md`
- All other NFRs mapped to specific architectural decisions

### Gaps Identified and Resolved

| Gap | Resolution |
|-----|-----------|
| NFR12: Docker restart policy not specified | Added `restart: unless-stopped` to enforcement guidelines |
| FR36: Email queuing not designed | Added disk-backed queue design to `internal/email/` with 72-hour TTL |
| NFR21: No new-pipeline procedure | Added 6-step mechanical runbook |
| Missing `docs/runbooks/` directory | Added to project structure and Phase 1-2 build order |

### Architecture Completeness Checklist

**✅ Requirements Analysis**
- [x] Project context thoroughly analyzed (47 FRs, 23 NFRs)
- [x] Scale and complexity assessed (Medium)
- [x] Technical constraints identified (32GB RAM, single GPU, single node)
- [x] Cross-cutting concerns mapped (8 concerns)

**✅ Architectural Decisions**
- [x] Critical decisions documented with versions (Go 1.26, Compose v5 spec)
- [x] Technology stack fully specified (Go stdlib + `robfig/cron`)
- [x] Integration patterns defined (HTTP/REST, Docker network, Loki log driver)
- [x] Performance considerations addressed (memory budget, retry constants)

**✅ Implementation Patterns**
- [x] Naming conventions established (snake_case everywhere)
- [x] Structure patterns defined (cmd/ + internal/ + configs/)
- [x] Communication patterns specified (InferenceClient interface, /health, /status)
- [x] Process patterns documented (graceful shutdown, config loading, retry, error wrapping, email queue)

**✅ Project Structure**
- [x] Complete directory structure defined with phase annotations
- [x] Component boundaries established (service + package boundary tables)
- [x] Integration points mapped (internal + external tables)
- [x] Requirements to structure mapping complete (FR → directory table)
- [x] Phase Build Order specified
- [x] Runbook directory and new-pipeline procedure documented

### Architecture Readiness Assessment

**Overall Status:** READY FOR IMPLEMENTATION

**Confidence Level:** High

**Key Strengths:**
- Every FR has a clear home in the directory structure
- Patterns are specific enough to prevent agent divergence (exact JSON formats, exact function signatures, exact code skeletons)
- Phase Build Order prevents premature scaffolding
- Memory budget is explicit and validated
- Single external dependency (`robfig/cron`) — minimal supply chain risk
- Email queue design ensures FR36 compliance for offline resilience
- New-pipeline runbook ensures NFR21 (adding pipelines in <1 hour)

**Areas for Future Enhancement:**
- RAG query interface (Phase 6) — TBD, not yet designed
- Webhook authentication (Phase 5) — deferred by design
- CI/CD pipeline (Phase 8) — using manual Docker Compose until then

### Implementation Handoff

**AI Agent Guidelines:**
- Follow all architectural decisions exactly as documented
- Use implementation patterns consistently across all components
- Respect Phase Build Order — only scaffold the current phase
- Refer to this document for all architectural questions
- The `InferenceClient` interface is the load-bearing contract — never bypass it

**First Implementation Priority:**
1. Run `scripts/init-host.sh` to prepare host
2. Stand up Docker Compose with core infrastructure (Phase 1-2)
3. Create `docs/runbooks/` with initial runbooks
4. Build walking skeleton `cmd/hn-digest/` with `internal/ai/` and `internal/email/` (Phase 3)
