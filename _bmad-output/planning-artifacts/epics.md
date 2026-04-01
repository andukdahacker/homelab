---
stepsCompleted: ['step-01-validate-prerequisites', 'step-02-design-epics', 'step-03-create-stories', 'step-04-final-validation']
inputDocuments: ['prd.md', 'architecture.md']
---

# homelab - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for homelab, decomposing the requirements from the PRD and Architecture requirements into implementable stories.

## Requirements Inventory

### Functional Requirements

- FR1: Owner can deploy all services via a single Docker Compose configuration
- FR2: Owner can access all web-based services through Caddy reverse proxy with HTTPS
- FR3: Owner can access the homelab remotely from any device via Tailscale VPN
- FR4: Owner can monitor system resource utilization (CPU, RAM, GPU, disk) via Grafana dashboards
- FR5: Owner can view Docker container health and status via Grafana
- FR6: Owner can perform automated backups of all Docker volumes and configurations via Restic
- FR7: Owner can restore from backups to recover the system after failure
- FR8: Owner can manage Git repositories locally via Gitea
- FR9: Owner can run local AI inference (summarization, classification, embeddings) via Ollama
- FR10: Owner can route complex reasoning tasks to Claude API
- FR11: System can fall back to local Ollama inference when Claude API is unavailable
- FR12: Owner can swap Ollama models (size/type) based on workload and resource constraints
- FR13: System can route AI inference requests to the appropriate engine (local Ollama or cloud Claude) based on task type, ensuring consistent routing logic across all pipelines
- FR14: Owner can create, edit, and test automation workflows via n8n web UI
- FR15: Owner can trigger workflows manually via webhook URLs
- FR16: System can execute scheduled workflows on defined intervals (cron-based)
- FR17: n8n workflows can call Ollama and Claude API for AI-powered processing steps
- FR18: System can scrape content from Hacker News, GitHub trending, and Reddit on a scheduled basis
- FR19: System can identify and group thematically related items across different sources into clusters using AI analysis
- FR20: System can score opportunities against owner's skills and interests
- FR21: System can generate and deliver a formatted morning digest email with scored ideas, supporting evidence, and competitive gaps
- FR22: Owner can trigger a manual idea pipeline run with a custom topic
- FR23: System can ingest production logs from Railway via log drains
- FR24: System can ingest events from Sentry via webhooks
- FR25: System can ingest logs from GCP via Cloud Logging export
- FR26: System can perform AI-powered anomaly detection on ingested logs
- FR27: System can generate root cause analysis and suggested fixes for detected issues
- FR28: System can deliver alert emails with incident explanation within 15 minutes of occurrence
- FR29: Owner can view aggregated logs from all sources via Grafana + Loki
- FR30: System can generate embeddings from all system outputs (trend analyses, incident reports, automation results)
- FR31: System can index embeddings in Qdrant with source metadata and timestamps
- FR32: Owner can query the knowledge base with natural language and receive relevant results
- FR33: System can filter or boost search results by recency to prevent stale knowledge from dominating
- FR34: System can send formatted emails (digests, alerts, summaries) via SMTP
- FR35: Owner can receive all system outputs (digests, alerts, summaries) via email on both mobile and desktop
- FR36: System can queue email delivery when internet connectivity is lost and deliver on reconnection, with a maximum retention of 72 hours (older queued items discarded to prevent alert flooding)
- FR37: All custom Go services expose `/health` endpoints for Docker health checks
- FR38: All custom Go services expose `/status` endpoints reporting last run time, success/failure, and error context
- FR39: System can aggregate structured logs from all services via Loki
- FR40: Owner can view pipeline execution health and history via Grafana dashboards
- FR41: System can continue operating local services (Ollama, Grafana, Loki, Gitea, Qdrant, n8n) when internet is unavailable
- FR42: System can pause and automatically resume internet-dependent pipelines (scraping, log drains, email) on reconnection
- FR43: System can transcribe voice recordings using Whisper and sync via Syncthing
- FR44: System can extract structured data (amounts, categories, dates) from receipts and invoices received via email
- FR45: System can monitor platform costs and uptime across Railway, GCP, and Sentry
- FR46: System can generate meeting preparation briefings from calendar, repos, and relevant docs
- FR47: System can scrape, summarize, and index saved bookmarks into the knowledge base

### NonFunctional Requirements

- NFR1: Local Ollama inference for summarization tasks (8B models) completes within 30 seconds per request
- NFR2: Production alert pipeline (log ingestion → AI triage → email) completes end-to-end within 15 minutes
- NFR3: Qdrant vector search queries return results within 5 seconds
- NFR4: Grafana dashboards load within 10 seconds
- NFR5: System operates within 32GB RAM budget across all containers, with per-service memory limits enforced via Docker
- NFR6: All service web UIs accessible only via Tailscale VPN — no public-facing ports except Caddy (if needed for webhooks)
- NFR7: API keys (Claude, external services) stored as Docker secrets or environment variables, never hardcoded in source
- NFR8: Restic backups encrypted at rest
- NFR9: Gitea repositories require authentication for push/pull operations
- NFR10: Webhook endpoints (for log drains, Sentry) validate request signatures where supported
- NFR11: System achieves 24/7 uptime with tolerance for planned maintenance windows (monthly)
- NFR12: All Docker containers restart automatically on failure (restart policy: unless-stopped)
- NFR13: Restic backups run daily with at least 7 days of retention
- NFR14: System continues operating core local services during internet outages (see Degraded Mode Operation table)
- NFR15: No single service failure cascades to take down unrelated services
- NFR16: All external API integrations (HN, GitHub, Reddit, Railway, Sentry, GCP) handle rate limits gracefully with exponential backoff
- NFR17: External API failures do not block unrelated pipelines — each pipeline operates independently
- NFR18: SMTP email delivery supports TLS encryption
- NFR19: All custom Go services produce structured JSON logs compatible with Loki ingestion
- NFR20: Total weekly maintenance effort remains under 2 hours
- NFR21: Adding a new automation pipeline follows a documented pattern and is achievable within 1 hour for simple cases
- NFR22: All services updatable independently via Docker image pulls without rebuilding the entire stack
- NFR23: Docker Compose configuration version-controlled in Gitea

### Additional Requirements

- Go monorepo structure: `cmd/` for services, `internal/` for shared packages, `configs/` for service configs
- Go 1.26 with stdlib-only approach (net/http 1.22+ routing, log/slog) plus `robfig/cron` as only external dependency
- Custom project structure — no off-the-shelf starter template; project initialization is first implementation story
- `scripts/init-host.sh` for first-boot host preparation (create /data/homelab/* dirs, copy .env.example → .env)
- Docker Compose single `homelab` bridge network; all services reference each other by service name
- Bind mount volumes to `/data/homelab/<service>/` for all persistent data
- Memory budget enforced per container via `mem_limit` (Ollama 16GB, Qdrant 2GB, Grafana 512MB, Loki 1GB, n8n 1GB, Gitea 512MB, Caddy 256MB, Go services 256MB each, OS ~4GB, ~5GB headroom)
- `InferenceClient` interface in `internal/ai/client.go` as core AI routing contract with Ollama + Claude implementations
- Standard retry pattern: 3 max attempts, 1s base delay, 30s max delay, exponential with jitter
- Loki Docker log driver plugin (no Promtail container) for log collection
- `log/slog` JSON handler initialized in each `main.go` — no shared logging package
- Standard `/health` (200 ok / 503 degraded) and `/status` (last_run, last_result, error, runs_today, next_run) endpoint contracts
- Multi-stage Dockerfile pattern: `golang:1.26` build → `gcr.io/distroless/static` runtime
- Graceful shutdown via `signal.NotifyContext` in every `main.go`
- Config loading via `Config` struct + `LoadConfig()` + `getEnv()` helper per service
- Disk-backed email queue in `internal/email/` with 72-hour TTL for offline resilience (FR36)
- Table-driven tests, integration tests with `//go:build integration` tag, mock InferenceClient in `internal/ai/aitest/`
- Phase Build Order enforced: only scaffold files/directories for the current phase
- New pipeline runbook (6-step procedure) documented in `docs/runbooks/new-pipeline.md`
- `restart: unless-stopped` on every Docker Compose service
- `.env` file for secrets (git-ignored), `.env.example` committed as template

### UX Design Requirements

No UX design document — no custom UI in this project. All user-facing output is delivered via email. n8n and Grafana provide their own web UIs.

### FR Coverage Map

- FR1: Epic 1 — Deploy all services via Docker Compose
- FR2: Epic 1 — Caddy reverse proxy with HTTPS
- FR3: Epic 1 — Remote access via Tailscale VPN
- FR4: Epic 2 — System resource monitoring via Grafana
- FR5: Epic 2 — Docker container health via Grafana
- FR6: Epic 2 — Automated Restic backups
- FR7: Epic 2 — Restore from backups
- FR8: Epic 1 — Local Git hosting via Gitea
- FR9: Epic 3 — Local AI inference via Ollama
- FR10: Epic 3 — Cloud AI via Claude API
- FR11: Epic 3 — Ollama fallback when Claude unavailable
- FR12: Epic 3 — Swap Ollama models
- FR13: Epic 3 — AI routing logic (Ollama/Claude)
- FR14: Epic 4 — n8n workflow creation
- FR15: Epic 4 — Manual webhook triggers
- FR16: Epic 4 — Scheduled workflow execution
- FR17: Epic 4 — n8n + Ollama/Claude integration
- FR18: Epic 5 — Multi-source scraping (HN, GitHub, Reddit)
- FR19: Epic 5 — AI clustering across sources
- FR20: Epic 5 — Opportunity scoring
- FR21: Epic 5 — Morning digest email
- FR22: Epic 5 — Manual idea pipeline trigger
- FR23: Epic 6 — Railway log ingestion
- FR24: Epic 6 — Sentry event ingestion
- FR25: Epic 6 — GCP log ingestion
- FR26: Epic 6 — AI anomaly detection
- FR27: Epic 6 — Root cause analysis and suggested fixes
- FR28: Epic 6 — Alert emails within 15 minutes
- FR29: Epic 6 — Aggregated logs from all sources via Grafana + Loki
- FR30: Epic 7 — Generate embeddings from system outputs
- FR31: Epic 7 — Index embeddings in Qdrant
- FR32: Epic 7 — Natural language knowledge base queries
- FR33: Epic 7 — Recency-aware search results
- FR34: Epic 3 — SMTP email delivery
- FR35: Epic 3 — Email delivery to mobile and desktop
- FR36: Epic 3 — Email queue with 72-hour TTL
- FR37: Epic 3 — /health endpoints for Docker health checks
- FR38: Epic 3 — /status endpoints for pipeline visibility
- FR39: Epic 2 — Structured log aggregation via Loki
- FR40: Epic 3 — Pipeline health dashboards in Grafana
- FR41: Epic 1 — Local services operate during internet outages
- FR42: Epic 3 — Pause/resume internet-dependent pipelines
- FR43: Epic 8 — Voice recording transcription (Whisper + Syncthing)
- FR44: Epic 8 — Receipt/invoice data extraction
- FR45: Epic 8 — Platform cost and uptime monitoring
- FR46: Epic 8 — Meeting preparation briefings
- FR47: Epic 8 — Bookmark rescue and RAG indexing

## Epic List

### Epic 1: Platform Foundation & Remote Access
Owner can deploy the entire homelab stack with one command, access all services remotely via Tailscale, and manage code in Gitea — the base everything else builds on.
**FRs covered:** FR1, FR2, FR3, FR8, FR41

### Epic 2: System Monitoring & Data Protection
Owner can monitor system health (CPU, RAM, GPU, disk, container status) via Grafana dashboards, aggregate logs via Loki, and protect all data with automated encrypted backups and verified restore.
**FRs covered:** FR4, FR5, FR6, FR7, FR39

### Epic 3: AI-Powered HN Digest — Walking Skeleton
Owner receives a daily AI-summarized HN digest email, proving the complete end-to-end integration pattern: scrape → AI inference (Ollama/Claude with routing & fallback) → email delivery with offline queuing. Establishes all shared Go service contracts (/health, /status, structured logging).
**FRs covered:** FR9, FR10, FR11, FR12, FR13, FR34, FR35, FR36, FR37, FR38, FR40, FR42

### Epic 4: Workflow Automation
Owner can build, test, and run custom automation workflows via n8n with AI-powered processing steps, triggerable manually via webhooks or on cron schedules.
**FRs covered:** FR14, FR15, FR16, FR17

### Epic 5: Trend Analysis & Idea Generation
Owner receives a comprehensive morning digest email with AI-clustered trends from HN, GitHub trending, and Reddit, scored against personal skills and interests, with competitive gap analysis.
**FRs covered:** FR18, FR19, FR20, FR21, FR22

### Epic 6: Production Monitoring & Alerting
Owner gets proactive email alerts with AI-powered root cause analysis and suggested fixes for production issues across personal projects (Railway, Sentry, GCP), within 15 minutes of occurrence.
**FRs covered:** FR23, FR24, FR25, FR26, FR27, FR28, FR29

### Epic 7: Knowledge Layer & RAG
Owner can query a compounding knowledge base that auto-indexes all system outputs (trend analyses, incident reports, automation results) with natural language search and recency-aware ranking.
**FRs covered:** FR30, FR31, FR32, FR33

### Epic 8: Life Automation (Vision)
Owner can automate personal productivity tasks: voice note transcription, expense/invoice extraction, platform cost monitoring, meeting prep, and bookmark rescue into the knowledge base.
**FRs covered:** FR43, FR44, FR45, FR46, FR47

## Epic 1: Platform Foundation & Remote Access

Owner can deploy the entire homelab stack with one command, access all services remotely via Tailscale, and manage code in Gitea — the base everything else builds on.

### Story 1.1: Project Repository & Host Initialization

As a homelab owner,
I want a fully initialized project repository and host setup script,
So that I can go from a fresh Fedora install to a ready-to-run homelab with one script.

**Acceptance Criteria:**

**Given** a fresh clone of the homelab repository
**When** I review the project structure
**Then** it contains `go.mod` (module `github.com/ducdo/homelab`), `.env.example`, `.gitignore`, `scripts/init-host.sh`, `configs/` directory, `docker-compose.yml` skeleton, and `README.md`
**And** `.gitignore` excludes `.env`, `/data/`, `.idea/`, `.vscode/`, `*.swp`

**Given** a fresh Fedora host with Docker installed
**When** I run `scripts/init-host.sh`
**Then** it creates all `/data/homelab/<service>/` bind mount directories (ollama, grafana, loki, qdrant, gitea, n8n, caddy)
**And** it copies `.env.example` to `.env` if `.env` does not already exist
**And** it sets appropriate directory permissions

**Given** the `docker-compose.yml` skeleton
**When** I inspect it
**Then** it defines a `homelab` bridge network
**And** it references `.env` via `env_file` directive

### Story 1.2: Docker Compose Core Services & Caddy Reverse Proxy

As a homelab owner,
I want all core services defined in Docker Compose with Caddy routing and HTTPS,
So that I can bring up the entire stack with `docker compose up -d` and access every service through clean URLs.

**Acceptance Criteria:**

**Given** a populated `.env` file and completed host initialization
**When** I run `docker compose up -d`
**Then** Ollama, Grafana, Loki, Qdrant, Gitea, n8n, and Caddy containers all start successfully
**And** each service has `restart: unless-stopped` policy
**And** each service has `mem_limit` matching the architecture memory budget (Ollama 16GB, Qdrant 2GB, Grafana 512MB, Loki 1GB, n8n 1GB, Gitea 512MB, Caddy 256MB)
**And** all services are on the `homelab` bridge network
**And** each service uses bind mounts to `/data/homelab/<service>/`

**Given** all services are running
**When** I access Grafana, Gitea, n8n, or Qdrant web UIs via Caddy
**Then** Caddy routes each to the correct service with HTTPS
**And** the Caddyfile is stored in `configs/caddy/Caddyfile`

**Given** one service crashes
**When** Docker detects the failure
**Then** the container restarts automatically
**And** no other services are affected (FR41, NFR15)

### Story 1.3: Tailscale VPN & Remote Access

As a homelab owner,
I want secure remote access to all services via Tailscale,
So that I can manage my homelab from any device without exposing services to the public internet.

**Acceptance Criteria:**

**Given** Tailscale is configured on the homelab host
**When** I connect from a remote device via Tailscale
**Then** I can access all Caddy-routed web UIs (Grafana, Gitea, n8n, Qdrant dashboard)
**And** no service web UIs are accessible from outside the Tailscale network (NFR6)

**Given** Tailscale is connected on a mobile device
**When** I access Grafana
**Then** dashboards load and are usable on a mobile browser

**Given** internet connectivity is lost on the homelab
**When** I am on the same local network
**Then** local services (Ollama, Grafana, Loki, Gitea, Qdrant, n8n) remain fully operational (FR41)

### Story 1.4: Gitea Setup & Repository Hosting

As a homelab owner,
I want Gitea configured with authentication and the homelab repo hosted locally,
So that I can version-control all Docker Compose configuration and access my code without external dependencies.

**Acceptance Criteria:**

**Given** Gitea is running via Docker Compose
**When** I access the Gitea web UI via Caddy
**Then** I can create an account and log in

**Given** I am authenticated in Gitea
**When** I push the homelab repository to Gitea
**Then** the push succeeds and the repository is visible in the Gitea UI
**And** the `docker-compose.yml` and all config files are version-controlled (NFR23)

**Given** I am not authenticated
**When** I attempt to push or pull from a Gitea repository
**Then** the operation is rejected with an authentication error (NFR9)

## Epic 2: System Monitoring & Data Protection

Owner can monitor system health (CPU, RAM, GPU, disk, container status) via Grafana dashboards, aggregate logs via Loki, and protect all data with automated encrypted backups and verified restore.

### Story 2.1: Loki Log Aggregation & Grafana Datasource

As a homelab owner,
I want all container logs aggregated in Loki and queryable through Grafana,
So that I can search and analyze logs from any service in one place.

**Acceptance Criteria:**

**Given** all services are running in Docker Compose
**When** I inspect the `docker-compose.yml`
**Then** every service has the Loki Docker log driver configured with `loki-url: "http://localhost:3100/loki/api/v1/push"`
**And** Loki config is stored in `configs/loki/config.yaml`

**Given** services are producing logs
**When** I open Grafana and navigate to the Explore view
**Then** Loki is auto-provisioned as a datasource via `configs/grafana/provisioning/datasources/loki.yaml`
**And** I can query logs by container name, service, and log level
**And** structured JSON log fields are parseable in Grafana (NFR19)

**Given** a service writes a structured JSON log line
**When** I query Loki for that service
**Then** the log line appears within 30 seconds with all JSON fields indexed

### Story 2.2: System & Container Health Dashboards

As a homelab owner,
I want Grafana dashboards showing system resources and container health,
So that I can spot problems at a glance during my weekly maintenance check.

**Acceptance Criteria:**

**Given** Grafana is running with Loki connected
**When** I open the System Overview dashboard
**Then** I see current CPU, RAM, GPU, and disk utilization
**And** the dashboard loads within 10 seconds (NFR4)

**Given** all Docker containers are running
**When** I open the Container Health dashboard
**Then** I see each container's status (running/stopped/restarting), uptime, memory usage, and restart count (FR5)

**Given** dashboards are defined as JSON files
**When** I check the repository
**Then** `configs/grafana/dashboards/system-overview.json` and `configs/grafana/dashboards/container-health.json` exist
**And** they are auto-provisioned via `configs/grafana/provisioning/dashboards/dashboards.yaml`

### Story 2.3: Automated Backups with Restic

As a homelab owner,
I want daily encrypted backups of all critical data to off-machine storage,
So that I can recover from hardware failure without losing important data.

**Acceptance Criteria:**

**Given** Restic is configured with an off-machine backup target
**When** the daily backup runs
**Then** it backs up Gitea repos, n8n workflows, Grafana dashboards, service configs, and Qdrant collections
**And** it skips logs and rebuildable vector data to keep backup size manageable
**And** backups are encrypted at rest (NFR8)

**Given** backups have been running for more than 7 days
**When** I check Restic snapshots
**Then** at least 7 daily snapshots are retained (NFR13)
**And** older snapshots are pruned automatically

**Given** the backup schedule is configured
**When** I inspect the setup
**Then** the backup runs daily without manual intervention
**And** backup success/failure is visible in logs (queryable via Loki)

### Story 2.4: Backup Restore & Recovery Verification

As a homelab owner,
I want a documented and verified restore procedure,
So that I can confidently recover the entire system after a failure.

**Acceptance Criteria:**

**Given** at least one Restic backup snapshot exists
**When** I follow the restore runbook
**Then** I can restore Gitea repos, n8n workflows, Grafana dashboards, and service configs to their backed-up state
**And** all restored services start and function correctly after `docker compose up -d`

**Given** the restore procedure is complete
**When** I check the repository
**Then** a restore runbook exists in `docs/runbooks/` covering step-by-step recovery from backup

**Given** I want to verify backup integrity
**When** I run a Restic verify/check command
**Then** it confirms all backup data is intact and not corrupted

## Epic 3: AI-Powered HN Digest — Walking Skeleton

Owner receives a daily AI-summarized HN digest email, proving the complete end-to-end integration pattern: scrape → AI inference (Ollama/Claude with routing & fallback) → email delivery with offline queuing. Establishes all shared Go service contracts (/health, /status, structured logging).

### Story 3.1: AI Routing Layer (`internal/ai`)

As a homelab owner,
I want a shared AI inference layer that routes requests between Ollama and Claude with automatic fallback,
So that all pipelines get reliable AI processing regardless of Claude API availability.

**Acceptance Criteria:**

**Given** the `internal/ai/` package exists
**When** I inspect `client.go`
**Then** it defines the `InferenceClient` interface with `Complete(ctx context.Context, prompt string, opts ...Option) (string, error)`

**Given** Ollama is running on the Docker network
**When** a service calls `OllamaClient.Complete()` with a summarization prompt
**Then** it returns a response within 30 seconds for 8B models (NFR1)
**And** errors are wrapped with `fmt.Errorf` context

**Given** a valid Claude API key is set in environment variables (NFR7)
**When** a service calls `ClaudeClient.Complete()` with a reasoning prompt
**Then** it returns a response from the Claude API
**And** errors are wrapped with `fmt.Errorf` context

**Given** Claude API is unavailable or times out
**When** the router attempts a Claude request
**Then** it falls back to Ollama automatically (FR11)
**And** logs a WARN via `slog`: `"claude unavailable, falling back to ollama"`
**And** retries follow the standard pattern: 3 max attempts, 1s base delay, 30s max delay, exponential with jitter

**Given** a task type is specified (e.g., summarization vs. complex reasoning)
**When** the router selects an inference engine
**Then** it routes routine tasks to Ollama and complex tasks to Claude (FR13)

**Given** the test suite
**When** I run `go test ./internal/ai/...`
**Then** `router_test.go` passes with table-driven tests covering: successful Ollama call, successful Claude call, Claude timeout with Ollama fallback, both unavailable error
**And** `internal/ai/aitest/mock.go` provides a shared mock `InferenceClient` for use by all service tests

### Story 3.2: Email Delivery Service (`internal/email`)

As a homelab owner,
I want reliable email delivery that queues messages when offline and retries automatically,
So that I never miss a digest or alert even during internet outages.

**Acceptance Criteria:**

**Given** SMTP credentials are configured in environment variables
**When** a service sends an email via `internal/email`
**Then** it delivers the email via SMTP with TLS encryption (NFR18)
**And** the email is formatted and readable on both mobile and desktop (FR35)

**Given** the SMTP server is unreachable
**When** a service attempts to send an email
**Then** the email is serialized to a JSON file in `/data/homelab/<service>/email-queue/`
**And** the filename includes a timestamp for TTL calculation

**Given** queued emails exist and SMTP becomes available
**When** the retry timer fires (every 5 minutes)
**Then** queued emails are delivered via SMTP
**And** successfully sent queue files are deleted

**Given** a queued email is older than 72 hours
**When** the retry timer processes the queue
**Then** the expired email is discarded without sending (FR36)
**And** an INFO log is emitted noting the discard

**Given** the test suite
**When** I run `go test ./internal/email/...`
**Then** tests pass covering: successful send, SMTP failure queues to disk, retry delivers queued email, TTL discard after 72 hours

### Story 3.3: Health & Status Handlers (`internal/health`)

As a homelab owner,
I want every Go service to expose standardized health and status endpoints,
So that Docker can health-check containers and Grafana can display pipeline execution history.

**Acceptance Criteria:**

**Given** a Go service imports `internal/health`
**When** a GET request hits `/health`
**Then** it returns `{"status": "ok"}` with HTTP 200 when healthy
**Or** it returns `{"status": "degraded", "reason": "<description>"}` with HTTP 503 when degraded

**Given** a Go service has run at least one pipeline execution
**When** a GET request hits `/status`
**Then** it returns JSON with `service`, `last_run` (ISO 8601), `last_result` ("success"/"failure"), `error` (null or string), `runs_today` (int), `next_run` (ISO 8601)
**And** all JSON fields use `snake_case` naming
**And** null is used for absent values, not empty strings

**Given** a service registers a health check function
**When** a dependency (e.g., Ollama) becomes unreachable
**Then** `/health` reports `degraded` with the reason

**Given** the test suite
**When** I run `go test ./internal/health/...`
**Then** tests pass covering: healthy response, degraded response, status after successful run, status after failed run

### Story 3.4: HN Digest Service (`cmd/hn-digest`)

As a homelab owner,
I want a daily email digest of AI-summarized Hacker News top stories,
So that I stay informed on tech trends without manually browsing HN.

**Acceptance Criteria:**

**Given** the `cmd/hn-digest/` service is configured with `config.go` using the standard `Config` struct + `LoadConfig()` + `getEnv()` pattern
**When** I inspect the configuration
**Then** it reads `OLLAMA_URL`, `SMTP_HOST`, `CRON_SCHEDULE` (default `"0 2 * * *"`), and other required env vars from `.env`

**Given** the cron schedule triggers (default: 2 AM daily)
**When** the pipeline executes
**Then** it scrapes HN top stories via the HN API
**And** sends stories to Ollama via `InferenceClient` for summarization and clustering
**And** formats a clean, scannable digest email
**And** sends the digest via `internal/email`
**And** logs the pipeline run via `slog` with `service: "hn-digest"` and `component` keys (NFR19)

**Given** the pipeline completes
**When** I query `/status`
**Then** it shows `last_run`, `last_result: "success"`, `runs_today`, and `next_run`

**Given** the HN API is unreachable
**When** the pipeline runs
**Then** it logs an ERROR, updates `/status` with `last_result: "failure"` and error context
**And** does not send a partial/empty digest
**And** does not affect other services (NFR17)

**Given** the service starts
**When** I inspect `main.go`
**Then** it initializes `slog` with JSON handler and `service: "hn-digest"`
**And** starts the HTTP server (for `/health` and `/status`), starts the cron scheduler
**And** implements graceful shutdown via `signal.NotifyContext`

**Given** the Dockerfile
**When** I build the image
**Then** it uses multi-stage build: `golang:1.26` → `gcr.io/distroless/static`

**Given** Docker Compose
**When** I inspect the `hn-digest` service definition
**Then** it has `mem_limit: 256m`, `restart: unless-stopped`, Loki log driver, `homelab` network, `env_file`, and bind mount to `/data/homelab/hn-digest/`

**Given** internet connectivity is lost
**When** the pipeline runs
**Then** HN scraping fails gracefully, email is queued to disk, and the service continues running for the next scheduled attempt (FR42)

### Story 3.5: Pipeline Health Dashboard & Runbook

As a homelab owner,
I want a Grafana dashboard showing pipeline execution health and a documented procedure for adding new pipelines,
So that I can monitor all pipelines at a glance and add new ones in under an hour.

**Acceptance Criteria:**

**Given** the hn-digest service is running and exposing `/status`
**When** I open the Pipeline Health dashboard in Grafana
**Then** I see the service name, last run time, last result (success/failure), error details, runs today, and next scheduled run (FR40)
**And** the dashboard loads within 10 seconds (NFR4)

**Given** the dashboard JSON
**When** I check the repository
**Then** `configs/grafana/dashboards/pipeline-health.json` exists and is auto-provisioned

**Given** I want to add a new pipeline service
**When** I follow `docs/runbooks/new-pipeline.md`
**Then** it documents the 6-step procedure: create `cmd/<name>/`, copy skeleton, update config, add to Docker Compose, add bind mount to init script, build and test
**And** the procedure is achievable within 1 hour for simple cases (NFR21)

## Epic 4: Workflow Automation

Owner can build, test, and run custom automation workflows via n8n with AI-powered processing steps, triggerable manually via webhooks or on cron schedules.

### Story 4.1: n8n Workflow Configuration & AI Integration

As a homelab owner,
I want n8n configured with AI service credentials and a sample workflow demonstrating the pattern,
So that I can rapidly prototype new automations with AI-powered processing steps.

**Acceptance Criteria:**

**Given** n8n is running via Docker Compose (from Epic 1)
**When** I open the n8n web UI via Caddy
**Then** I can create, edit, and save workflows (FR14)

**Given** Ollama is running on the `homelab` network
**When** I create an n8n workflow that calls Ollama's REST API (`http://ollama:11434`)
**Then** the workflow successfully sends a prompt and receives an AI-generated response (FR17)

**Given** a Claude API key is configured in n8n credentials
**When** I create an n8n workflow that calls the Claude API
**Then** the workflow successfully sends a prompt and receives a response (FR17)

**Given** a sample AI-powered workflow exists (e.g., email trigger → Ollama summarization → formatted output)
**When** I inspect `configs/n8n/`
**Then** the workflow is exported as a JSON backup for version control

### Story 4.2: Scheduled & Webhook-Triggered Workflows

As a homelab owner,
I want workflows that run on schedules and can be triggered manually via webhook URLs,
So that I can automate recurring tasks and kick off one-off jobs from any device.

**Acceptance Criteria:**

**Given** a workflow with a cron trigger configured in n8n
**When** the scheduled time arrives
**Then** the workflow executes automatically (FR16)
**And** execution history is visible in the n8n UI

**Given** a workflow with a webhook trigger
**When** I send an HTTP request to the webhook URL
**Then** the workflow executes and processes the request (FR15)

**Given** I am connected via Tailscale on a mobile device
**When** I hit an n8n webhook URL from my phone
**Then** the workflow triggers successfully
**And** results arrive via email when the workflow completes

**Given** one workflow fails
**When** other workflows are scheduled to run
**Then** they execute independently and are not affected (NFR17)

## Epic 5: Trend Analysis & Idea Generation

Owner receives a comprehensive morning digest email with AI-clustered trends from HN, GitHub trending, and Reddit, scored against personal skills and interests, with competitive gap analysis.

### Story 5.1: Multi-Source Scraping (HN, GitHub Trending, Reddit)

As a homelab owner,
I want automated daily scraping of tech trends from HN, GitHub trending, and Reddit,
So that I have comprehensive raw signal from multiple sources for analysis.

**Acceptance Criteria:**

**Given** the `cmd/trend-analyzer/` service is created following the new-pipeline runbook
**When** I inspect the service structure
**Then** it has `main.go`, `config.go`, `Dockerfile`, and `integration_test.go` matching the standard skeleton
**And** `config.go` uses the `Config` struct + `LoadConfig()` + `getEnv()` pattern

**Given** the cron schedule triggers (default: daily, before the morning digest)
**When** the scraping pipeline runs
**Then** it fetches top/trending content from Hacker News API, GitHub trending, and Reddit (FR18)
**And** each source is scraped independently — one source failure does not block others
**And** results are stored as structured data for the clustering step

**Given** an external API rate-limits a request
**When** the scraper encounters a 429 or rate limit response
**Then** it retries with exponential backoff using the standard retry constants (NFR16)
**And** logs a WARN with source and retry context

**Given** all three sources are unreachable
**When** the pipeline runs
**Then** it logs ERRORs for each source, updates `/status` with `last_result: "failure"`
**And** does not send an empty digest

**Given** the Docker Compose definition
**When** I inspect the `trend-analyzer` service
**Then** it has `mem_limit: 256m`, `restart: unless-stopped`, Loki log driver, `homelab` network, and bind mount to `/data/homelab/trend-analyzer/`

### Story 5.2: AI Clustering & Opportunity Scoring

As a homelab owner,
I want AI-powered clustering of related trends across sources and scoring against my skills and interests,
So that I see consolidated opportunities ranked by personal relevance instead of raw noise.

**Acceptance Criteria:**

**Given** scraped content from multiple sources is available
**When** the clustering step runs
**Then** it sends content to the AI router (`InferenceClient`) for thematic analysis
**And** groups related items from different sources into clusters (FR19)
**And** each cluster has a title, summary, and list of contributing items with source attribution

**Given** clusters are identified
**When** the scoring step runs
**Then** each cluster is scored against the owner's skills and interests profile (FR20)
**And** the profile is configurable via environment variable or config file
**And** scores reflect relevance, novelty, and competitive gaps

**Given** Claude API is unavailable during clustering
**When** the AI router falls back to Ollama
**Then** clustering still completes with reduced quality
**And** a WARN is logged noting the fallback

### Story 5.3: Morning Digest Email & Manual Trigger

As a homelab owner,
I want a formatted morning digest email with scored ideas and a way to trigger custom topic analysis on demand,
So that I wake up to actionable opportunities and can explore specific topics whenever I want.

**Acceptance Criteria:**

**Given** clusters are scored and ranked
**When** the digest formatting step runs
**Then** it generates a clean, scannable email with: trend clusters ranked by score, supporting evidence per cluster, source links, and competitive gap analysis (FR21)
**And** the email is readable on both mobile and desktop

**Given** the digest is formatted
**When** the email is sent via `internal/email`
**Then** it delivers successfully to the configured recipient
**And** if SMTP is unavailable, the email is queued to disk for retry (FR36)

**Given** the service exposes a webhook endpoint
**When** I send an HTTP request with a custom topic parameter
**Then** the pipeline runs an on-demand analysis for that topic (FR22)
**And** delivers results via email when complete

**Given** the pipeline completes successfully
**When** I query `/status`
**Then** it shows `last_run`, `last_result: "success"`, `runs_today`, and `next_run`

## Epic 6: Production Monitoring & Alerting

Owner gets proactive email alerts with AI-powered root cause analysis and suggested fixes for production issues across personal projects (Railway, Sentry, GCP), within 15 minutes of occurrence.

### Story 6.1: Log Ingestion from Railway, Sentry & GCP

As a homelab owner,
I want production logs and events from my personal projects ingested into the homelab automatically,
So that the system has the raw signal needed to detect and diagnose issues.

**Acceptance Criteria:**

**Given** the `cmd/log-monitor/` service is created following the new-pipeline runbook
**When** I inspect the service structure
**Then** it has `main.go`, `config.go`, `Dockerfile`, and `integration_test.go` matching the standard skeleton

**Given** a Railway app is configured to send log drains to the log-monitor webhook endpoint
**When** Railway sends log data
**Then** the service ingests and parses the logs into a structured format (FR23)
**And** webhook request signatures are validated where supported (NFR10)

**Given** a Sentry project is configured to send webhooks to the log-monitor endpoint
**When** Sentry fires an event
**Then** the service ingests and parses the event into a structured format (FR24)
**And** webhook signatures are validated (NFR10)

**Given** GCP Cloud Logging is configured to export logs to the log-monitor
**When** GCP sends log data
**Then** the service ingests and parses the logs into a structured format (FR25)

**Given** Caddy is the reverse proxy
**When** I inspect the Caddyfile
**Then** the log-monitor webhook endpoints are publicly routable for external log sources (NFR6 exception for inbound webhooks)

**Given** one log source is unreachable or misconfigured
**When** other sources continue sending data
**Then** ingestion from working sources is unaffected (NFR17)

**Given** the Docker Compose definition
**When** I inspect the `log-monitor` service
**Then** it has `mem_limit: 256m`, `restart: unless-stopped`, Loki log driver, `homelab` network, and bind mount to `/data/homelab/log-monitor/`

### Story 6.2: AI Anomaly Detection & Root Cause Analysis

As a homelab owner,
I want AI-powered analysis of ingested production logs to detect anomalies and explain what went wrong,
So that I get actionable diagnosis instead of raw log noise.

**Acceptance Criteria:**

**Given** structured log data has been ingested from one or more sources
**When** the analysis pipeline processes the logs
**Then** it sends relevant log context to the AI router (`InferenceClient`) for anomaly detection (FR26)
**And** identifies patterns indicating errors, performance degradation, or unusual behavior

**Given** an anomaly is detected
**When** the AI analyzes the context
**Then** it generates a root cause analysis explaining what is failing and why (FR27)
**And** provides a suggested fix with specific actionable steps
**And** includes affected endpoints or components

**Given** Claude API is unavailable
**When** the AI router falls back to Ollama
**Then** anomaly detection and root cause analysis still complete with reduced quality
**And** a WARN is logged noting the fallback

**Given** no anomalies are detected in a batch of logs
**When** the analysis completes
**Then** no alert is generated
**And** `/status` is updated with `last_result: "success"`

### Story 6.3: Alert Email Delivery within 15 Minutes

As a homelab owner,
I want alert emails with incident explanation delivered within 15 minutes of occurrence,
So that I can respond to production issues before users notice.

**Acceptance Criteria:**

**Given** an anomaly is detected and root cause analysis is complete
**When** the alert email is formatted
**Then** it includes: what's failing, probable root cause, affected endpoints, and suggested fix (FR28)
**And** the email is clean and scannable on both mobile (triage) and desktop (fix)

**Given** an incident occurs
**When** the end-to-end pipeline runs (log ingestion → AI triage → email delivery)
**Then** the alert email is delivered within 15 minutes of the incident occurrence (NFR2)

**Given** SMTP is unavailable when an alert needs to be sent
**When** the email client attempts delivery
**Then** the alert is queued to disk and retried every 5 minutes (FR36)

**Given** the pipeline completes
**When** I query `/status`
**Then** it reflects the latest run with accurate `last_run`, `last_result`, and `next_run`

**Given** multiple incidents occur simultaneously across different projects
**When** the pipeline processes them
**Then** each generates an independent alert email
**And** one project's issues do not delay alerts for another (NFR17)

### Story 6.4: External Log Aggregation in Grafana

As a homelab owner,
I want to view aggregated production logs from all external sources alongside internal logs in Grafana,
So that I have a single pane of glass for all log data across my projects.

**Acceptance Criteria:**

**Given** the log-monitor service is ingesting logs from Railway, Sentry, and GCP
**When** ingested logs are forwarded to Loki (via structured slog output and Docker log driver)
**Then** external source logs are queryable in Grafana alongside internal service logs (FR29)
**And** logs are filterable by source (Railway, Sentry, GCP) and project

**Given** I open Grafana's Explore view
**When** I query for logs from a specific external source
**Then** results appear with source attribution, timestamp, and severity level
**And** I can correlate external production events with internal pipeline activity

**Given** 3-4 personal projects are monitored
**When** I view the aggregated log view
**Then** all projects' logs are visible and distinguishable

## Epic 7: Knowledge Layer & RAG

Owner can query a compounding knowledge base that auto-indexes all system outputs (trend analyses, incident reports, automation results) with natural language search and recency-aware ranking.

### Story 7.1: Qdrant Client & Embedding Pipeline (`internal/qdrant`)

As a homelab owner,
I want a shared Qdrant client with standardized embedding generation,
So that all pipeline services can index their outputs into the knowledge base consistently.

**Acceptance Criteria:**

**Given** the `internal/qdrant/` package is created
**When** I inspect `client.go`
**Then** it provides functions for: creating collections, upserting points with vectors and payloads, and searching by vector with filters

**Given** content needs to be embedded
**When** the client generates embeddings via Ollama's `nomic-embed-text` model
**Then** it produces 768-dimension vectors
**And** the embedding model is consistent across all producers (no per-service overrides)

**Given** a point is upserted into Qdrant
**When** I inspect the payload schema
**Then** it includes: `source` (service name), `source_type` (e.g., "trend_analysis", "incident_report", "digest"), `content` (original text), `summary`, `timestamp` (ISO 8601), and `metadata` (service-specific key-value pairs)

**Given** Qdrant is running on the `homelab` network
**When** the client connects to `qdrant:6333`
**Then** operations complete successfully
**And** errors are wrapped with `fmt.Errorf` context

**Given** the test suite
**When** I run `go test ./internal/qdrant/...`
**Then** tests pass covering: collection creation, point upsertion, vector search, error handling

### Story 7.2: Auto-Indexing System Outputs

As a homelab owner,
I want all pipeline outputs automatically indexed into the knowledge base,
So that the system accumulates intelligence over time and every analysis makes future queries smarter.

**Acceptance Criteria:**

**Given** the hn-digest service completes a pipeline run
**When** the digest is generated
**Then** each summarized story and the full digest are embedded and indexed in Qdrant via `internal/qdrant` (FR30, FR31)
**And** payloads include `source: "hn-digest"`, `source_type: "digest"`, and the run timestamp

**Given** the trend-analyzer service completes a pipeline run
**When** clusters and scored opportunities are generated
**Then** each cluster and its scored analysis are embedded and indexed in Qdrant
**And** payloads include `source: "trend-analyzer"`, `source_type: "trend_analysis"`, and the run timestamp

**Given** the log-monitor service detects and analyzes an incident
**When** root cause analysis is generated
**Then** the incident report is embedded and indexed in Qdrant
**And** payloads include `source: "log-monitor"`, `source_type: "incident_report"`, and the incident timestamp

**Given** indexing fails (Qdrant unreachable)
**When** a pipeline attempts to index
**Then** the pipeline still completes its primary function (email delivery)
**And** an ERROR is logged noting the indexing failure
**And** the pipeline does not retry indexing (next run will index fresh content)

### Story 7.3: Natural Language Query Interface

As a homelab owner,
I want to query my knowledge base with natural language and get relevant, recency-aware results,
So that I can instantly retrieve past analyses, incidents, and trends without digging through email history.

**Acceptance Criteria:**

**Given** the knowledge base contains indexed system outputs
**When** I submit a natural language query (e.g., "WebSocket library trending last two weeks")
**Then** the query is embedded using `nomic-embed-text` via Ollama
**And** Qdrant returns semantically relevant results within 5 seconds (NFR3, FR32)

**Given** search results are returned
**When** results span different time periods
**Then** recent results are boosted or filterable by recency using timestamp metadata (FR33)
**And** the user can distinguish fresh insights from older knowledge

**Given** a query matches results from multiple sources
**When** results are displayed
**Then** each result shows its source (hn-digest, trend-analyzer, log-monitor), timestamp, summary, and original content

**Given** the query interface is implemented
**When** I access it
**Then** it is available as an HTTP API endpoint on a Go service
**And** accessible via Tailscale from both desktop and mobile

**Given** no results match the query
**When** the search returns empty
**Then** a clear "no results found" response is returned
**And** no error is logged (empty results are a valid outcome)

## Epic 8: Life Automation (Vision)

Owner can automate personal productivity tasks: voice note transcription, expense/invoice extraction, platform cost monitoring, meeting prep, and bookmark rescue into the knowledge base.

### Story 8.1: Voice Note Transcription Pipeline

As a homelab owner,
I want voice recordings automatically transcribed and indexed into my knowledge base,
So that I can capture ideas on the go and retrieve them later via natural language search.

**Acceptance Criteria:**

**Given** Syncthing is configured to sync a voice notes folder to the homelab
**When** a new audio file appears in the synced directory
**Then** the pipeline detects it and sends it to Whisper for transcription (FR43)
**And** the transcribed text is delivered via email with the original filename and timestamp

**Given** a transcription is complete
**When** the pipeline indexes the result
**Then** the transcribed text is embedded and indexed in Qdrant via `internal/qdrant`
**And** the payload includes `source: "voice-notes"`, `source_type: "transcription"`, and the recording timestamp

**Given** Whisper fails to transcribe a file (corrupt audio, unsupported format)
**When** the error occurs
**Then** an ERROR is logged with the filename and reason
**And** the file is skipped without blocking other transcriptions

### Story 8.2: Expense & Invoice Data Extraction

As a homelab owner,
I want structured data automatically extracted from receipts and invoices I receive via email,
So that expense tracking is automated instead of manual data entry.

**Acceptance Criteria:**

**Given** an email with a receipt or invoice attachment arrives
**When** the pipeline processes it
**Then** it extracts structured data: amount, currency, category, date, vendor, and line items (FR44)
**And** sends the extracted data via AI processing through `InferenceClient`

**Given** structured data is extracted
**When** the pipeline outputs results
**Then** data is written to a structured format (JSON or CSV) in `/data/homelab/expense-tracker/`
**And** a confirmation email summarizes what was extracted

**Given** the AI cannot confidently extract a field
**When** the extraction completes
**Then** uncertain fields are flagged in the output rather than silently guessed

### Story 8.3: Platform Cost & Uptime Monitoring

As a homelab owner,
I want automated monitoring of costs and uptime across my cloud platforms,
So that I catch unexpected charges or downtime without manually checking each dashboard.

**Acceptance Criteria:**

**Given** API credentials are configured for Railway, GCP, and Sentry
**When** the monitoring pipeline runs on schedule
**Then** it fetches current billing/usage data and service uptime from each platform (FR45)
**And** handles rate limits with exponential backoff (NFR16)

**Given** data is collected from all platforms
**When** the summary is generated
**Then** a report email is delivered with: cost per platform, cost trend vs. previous period, uptime percentage, and any incidents

**Given** one platform's API is unreachable
**When** the pipeline runs
**Then** it reports data from available platforms and notes which sources failed
**And** does not block the report for working sources

### Story 8.4: Meeting Preparation Briefings

As a homelab owner,
I want AI-generated meeting prep briefings before my meetings,
So that I walk in prepared with relevant context without manual research.

**Acceptance Criteria:**

**Given** calendar integration is configured (API or ICS feed)
**When** a meeting is approaching (configurable lead time)
**Then** the pipeline generates a briefing by querying: relevant repos (recent commits, open PRs), related docs from the knowledge base (Qdrant), and attendee context if available (FR46)

**Given** a briefing is generated
**When** it is delivered via email
**Then** it includes: meeting title and time, key discussion topics, relevant recent code changes, related knowledge base entries, and suggested talking points

**Given** no relevant context is found in the knowledge base or repos
**When** the briefing is generated
**Then** it includes the basic meeting details and notes that no additional context was found

### Story 8.5: Bookmark Rescue & Knowledge Indexing

As a homelab owner,
I want saved bookmarks automatically scraped, summarized, and indexed into my knowledge base,
So that bookmarked content is preserved and searchable even if the original pages disappear.

**Acceptance Criteria:**

**Given** a bookmark source is configured (browser export, Raindrop API, or similar)
**When** the pipeline detects new or unprocessed bookmarks
**Then** it scrapes the page content from each URL (FR47)
**And** handles unreachable URLs gracefully (log and skip)

**Given** page content is scraped
**When** the pipeline processes it
**Then** it generates an AI summary via `InferenceClient`
**And** embeds and indexes the summary plus original content in Qdrant
**And** payloads include `source: "bookmarks"`, `source_type: "bookmark"`, URL, page title, and save timestamp

**Given** a batch of bookmarks is processed
**When** the pipeline completes
**Then** a summary email is sent listing: bookmarks processed, bookmarks failed (with URLs), and total knowledge base entries added
