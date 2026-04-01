---
project_name: 'homelab'
user_name: 'Ducdo'
date: '2026-04-01'
sections_completed: ['technology_stack', 'language_rules', 'framework_rules', 'testing_rules', 'code_quality', 'workflow_rules', 'anti_patterns']
status: 'complete'
rule_count: 68
optimized_for_llm: true
---

# Project Context for AI Agents

_This file contains critical rules and patterns that AI agents must follow when implementing code in this project. Focus on unobvious details that agents might otherwise miss._

---

## Technology Stack & Versions

| Technology | Version/Variant | Key Constraint |
|---|---|---|
| Go | 1.26 (Green Tea GC) | Single module: `github.com/ducdo/homelab` |
| Go stdlib | `net/http` 1.22+, `log/slog`, `os.Getenv` | No external frameworks — stdlib only |
| `robfig/cron/v3` | v3 (5-field expressions) | Only external Go dependency — no other `go get` without justification |
| Docker Compose | v5 spec | Exclusive orchestration — no Kubernetes/Swarm |
| Dockerfile | `golang:1.26` → `gcr.io/distroless/static` | No shell in runtime image — never `sh -c` in CMD |
| Docker images | Pin specific version tags | Never use `latest` (e.g., `grafana/grafana:11.4`) |
| Ollama | REST API (unversioned) | Single-inference GPU bottleneck (RTX 5060 16GB) — pipelines must tolerate queuing |
| Qdrant | `nomic-embed-text` (768 dims) | Phase 6 only — do not import or reference before then |
| Loki | Docker log driver plugin | No Promtail container |
| Caddy | Reverse proxy + TLS | Tailscale VPN for all external access |
| RAM budget | 32GB total | Per-container `mem_limit` enforced — see architecture doc for allocation table |

## Critical Implementation Rules

### Go Language Rules

- **`net/http` routing**: Use 1.22+ method-pattern syntax — `mux.HandleFunc("GET /health", handler)`, not legacy `http.HandleFunc` with method checks inside
- **Error wrapping**: Always `fmt.Errorf("operation context: %w", err)` — never bare `return err`
- **Constructors**: `New` for single-type packages, `NewXxx` for multi-type (e.g., `ai.NewOllamaClient()`, `email.New()`)
- **Config pattern**: `Config` struct + `LoadConfig()` + `getEnv(key, fallback)` per service in `cmd/<service>/config.go` — no viper, no envconfig
- **`log/slog` init**: `slog.NewJSONHandler(os.Stdout, nil)` — default INFO level, no custom `ReplaceAttr`, no `LevelDebug` unless explicitly requested
- **`GOGC`/`GOMEMLIMIT`**: Do not set in Dockerfiles or code unless backed by measured data
- **`robfig/cron/v3` import**: Must use `github.com/robfig/cron/v3` — not the v1 path `github.com/robfig/cron`
- **Graceful shutdown**: Every `main.go` uses `signal.NotifyContext(context.Background(), syscall.SIGTERM, syscall.SIGINT)` — no alternative patterns (`os.Signal` channels, bare `select`)
- **InferenceClient interface**: All AI access through `internal/ai` — never call Ollama/Claude HTTP APIs directly from `cmd/` services
- **JSON struct tags**: `snake_case` always (e.g., `json:"last_run"`) — never `camelCase`
- **Null handling**: Use `null` for absent JSON values, not empty strings or zero values
- **Dates**: ISO 8601 via `time.RFC3339`
- **Exported types**: One primary type per package where possible
- **Package naming**: Short, lowercase, no underscores — `ai`, `email`, `health`, `qdrant`
- **File naming**: `snake_case.go` — e.g., `ollama_client.go`, `router_test.go`

### Docker & Infrastructure Rules

- **Docker Compose at repo root**: `docker-compose.yml` is the primary project interface — no `-f` flag needed
- **Single network**: All services on shared `homelab` bridge network — reference by service name
- **`restart: unless-stopped`**: Required on every service definition (NFR12)
- **Logging driver**: Every service gets Loki Docker log driver config (`loki-url: "http://localhost:3100/loki/api/v1/push"`)
- **Bind mounts**: `/data/homelab/<service>/` — not Docker named volumes
- **`mem_limit`**: Required on every container — no service without explicit memory allocation
- **`env_file`**: All services use `.env` — secrets never hardcoded in compose file
- **Service naming**: off-the-shelf = canonical lowercase (`ollama`, `grafana`); custom Go = hyphenated (`hn-digest`, `trend-analyzer`)
- **Build context**: Always `build.context: .` (repo root) with `build.dockerfile: cmd/<service>/Dockerfile` — Go monorepo needs `go.mod` + `internal/` in build context
- **Healthchecks**: Every custom Go service gets a compose `healthcheck` hitting `/health`; off-the-shelf services use their image's built-in healthcheck
- **`depends_on`**: Use for startup ordering only; `condition: service_healthy` only for true hard dependencies — never for Ollama (graceful degradation)
- **No Compose profiles**: Rejected by design — use explicit service names for partial bring-up (`docker compose up hn-digest ollama`)
- **`.env.example` discipline**: Every new env var added to a service must also get a placeholder entry in `.env.example`

### Service Architecture Pattern

- **`/health` endpoint**: Returns `{"status": "ok"}` (200) or `{"status": "degraded", "reason": "..."}` (503) — exact contract, consumed by Grafana dashboards — changing fields/structure breaks monitoring
- **`/status` endpoint**: Returns `{"service": "...", "last_run": "...", "last_result": "...", "error": null, "runs_today": N, "next_run": "..."}` — exact Grafana contract, no field changes
- **slog required keys**: Every log line must include `service` and `component` keys
- **slog key naming**: `snake_case` for all keys (e.g., `pipeline_run_id`, not `pipelineRunId`)
- **Retry pattern**: 3 attempts, 1s base delay, 30s max, exponential with jitter — constants from `internal/ai/router.go`, no per-service overrides
- **Pipeline state**: In-memory + JSON file on disk per service — no shared database
- **Email delivery**: All pipelines use `internal/email` — disk-backed queue with 72-hour TTL on SMTP failure
- **Phase discipline**: Only create files/directories for the current phase — reference Phase Build Order table in architecture doc for phase-to-directory mapping

### Testing Rules

- **Unit tests**: Co-located with source — `router_test.go` beside `router.go`
- **Test style**: Table-driven tests as the default pattern for all non-trivial functions
- **Test naming**: `TestFunctionName_scenario` (e.g., `TestRouter_fallbackOnClaudeTimeout`)
- **Integration tests**: `cmd/<service>/integration_test.go` with `//go:build integration` tag — run via `go test -tags=integration`
- **Mock pattern**: Interface-based injection only — use `internal/ai/aitest/mock.go` for shared mock `InferenceClient`
- **No external calls in unit tests**: Unit tests must never call Ollama, SMTP, or any external service
- **Integration test resilience**: Integration tests must skip (not fail) when dependencies are unavailable (Ollama not running, SMTP unreachable)
- **Test commands**: `go test ./...` for unit; `go test -tags=integration ./...` for integration (requires Docker services running)
- **No test containers**: Do not create docker-compose test profiles or test containers — integration tests run on host against running Docker services

### Code Quality & Style Rules

- **No linter/formatter config files**: Go's built-in `gofmt` is the formatter — no `.golangci-lint.yml` or custom lint configs unless explicitly added
- **File organization per service**: `main.go` (entry point, slog init, graceful shutdown, cron), `config.go` (Config struct + LoadConfig + getEnv), `Dockerfile`, `integration_test.go`
- **`internal/` package boundaries**: Each package has a single clear responsibility — see architecture doc Package Boundaries table
- **No premature abstraction**: Do not create `internal/logging/`, `internal/config/`, or `internal/utils/` packages — slog init is 2 lines inline per service, config is per-service, utilities don't exist
- **Comment policy**: Only where logic isn't self-evident — no boilerplate godoc on every exported function
- **No `fmt.Println` or `log.Println`**: All output through `slog` — the only exception is fatal startup errors before slog is initialized

### Development Workflow Rules

- **Local dev flow**: `scripts/init-host.sh` (first time) → populate `.env` from `.env.example` → `docker compose up -d` → develop Go services with `go run cmd/<service>/main.go` pointing env vars at Docker services
- **Build & test**: `go test ./...` (unit), `go test -tags=integration ./...` (integration, needs Docker services), `docker compose build <service>`
- **Deploy**: `docker compose up -d` for all, `docker compose up -d --build <service>` for single service update
- **No CI/CD until Phase 8**: Manual `docker compose` commands only
- **`.env` never committed**: `.env.example` is the committed template; `.env` is gitignored
- **`.gitignore` contents**: `.env`, `/data/`, `.idea/`, `.vscode/`, `*.swp`
- **New pipeline procedure**: Follow 6-step runbook in `docs/runbooks/new-pipeline.md` — copy from existing service, modify, add to compose, add bind mount dir to `init-host.sh`
- **Backup scope**: Config + critical data only (Gitea repos, n8n workflows, Grafana dashboards, Qdrant collections) — skip logs and vectors (rebuildable)

### Critical Anti-Patterns (Never Do)

- **Bare `return err`** — always wrap with `fmt.Errorf("context: %w", err)`
- **Custom `/health` or `/status` formats** — the exact JSON structures are Grafana contracts
- **`fmt.Println` or `log.Println`** — use `slog` exclusively
- **`camelCase` JSON fields** — `last_run` not `lastRun`
- **Tests hitting external services without `//go:build integration`** — unit tests are pure
- **`os.Signal` channels or bare `select` for shutdown** — `signal.NotifyContext` only
- **Per-service retry constants** — use the standard from `internal/ai/router.go`
- **Config via viper/envconfig** — stdlib `os.Getenv` with `getEnv()` helper only
- **Direct Ollama/Claude HTTP calls from `cmd/`** — all AI access through `InferenceClient` interface
- **`docker compose build ./cmd/<service>/`** — build context must be repo root
- **Docker `latest` tags** — pin specific versions for all images
- **Scaffolding future phases** — only build what the current phase requires
- **Named Docker volumes** — bind mounts to `/data/homelab/<service>/` only
- **Adding Go dependencies without justification** — `robfig/cron/v3` is the only external dep
- **Importing `internal/qdrant/` before Phase 6** — the package doesn't exist yet
- **Missing `service`/`component` keys in slog** — every log line needs them
- **Missing `restart: unless-stopped`** — required on every compose service
- **Missing `mem_limit`** — every container must have explicit memory allocation

---

## Usage Guidelines

**For AI Agents:**

- Read this file before implementing any code
- Follow ALL rules exactly as documented
- When in doubt, prefer the more restrictive option
- Reference the architecture doc (`_bmad-output/planning-artifacts/architecture.md`) for detailed design decisions, code skeletons, and phase build order

**For Humans:**

- Keep this file lean and focused on agent needs
- Update when technology stack or patterns change
- Review quarterly for outdated rules
- Remove rules that become obvious over time

Last Updated: 2026-04-01
