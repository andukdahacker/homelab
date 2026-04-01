---
stepsCompleted: ['step-01-init', 'step-02-discovery', 'step-02b-vision', 'step-02c-executive-summary', 'step-03-success', 'step-04-journeys', 'step-05-domain', 'step-06-innovation', 'step-07-project-type', 'step-08-scoping', 'step-09-functional', 'step-10-nonfunctional', 'step-11-polish', 'step-12-complete']
inputDocuments: ['product-brief-homelab.md']
workflowType: 'prd'
documentCounts:
  briefs: 1
  research: 0
  brainstorming: 0
  projectDocs: 0
classification:
  projectType: 'Infrastructure Platform / Developer Tool (self-hosted, personal)'
  domain: 'Developer Productivity / Personal Automation'
  complexity: 'medium'
  projectContext: 'greenfield'
  audience: 'solo / personal use'
---

# Product Requirements Document - Homelab AI Dev Server

**Author:** Ducdo
**Date:** 2026-03-29

## Executive Summary

A personal, always-on AI development server built on consumer hardware (Ryzen 9950X, RTX 5060 16GB, 32GB RAM) running Fedora. The system combines self-hosted dev infrastructure, hybrid AI inference (local Ollama + cloud Claude API), workflow automation via n8n, and intelligent monitoring into a single machine that actively works for its owner around the clock.

The core design principle is **infrastructure that thinks**: every service feeds signal into an AI intelligence layer, and the intelligence layer improves every service. The system scrapes and analyzes tech trends overnight, triages production logs before the owner wakes up, automates repetitive tasks that steal developer focus, and builds a compounding knowledge base that gets smarter over time.

**What Makes This Special:** No turnkey solution exists for a self-hosted AI dev companion. Individual components exist (n8n, Grafana, Ollama, Qdrant), but the value is in the **integration and intelligence layer** that connects them. The hybrid local/cloud AI architecture routes routine work (summarization, classification, embeddings) to Ollama at zero marginal cost, reserving Claude API for complex reasoning — delivering always-on AI capability without unpredictable cloud bills or external dependencies. The knowledge base (RAG with Qdrant) is the compounding engine: every log analyzed, every trend tracked, and every automation output indexed makes the next query smarter and faster.

**Classification:** Infrastructure Platform / Developer Tool (self-hosted, personal) | Domain: Developer Productivity / Personal Automation | Complexity: Medium | Greenfield | Solo developer (personal use only)

## Success Criteria

### User Success

- **Trend coverage you can't do manually:** The idea pipeline surfaces opportunities from HN, GitHub trending, and Reddit that would otherwise be missed entirely — ideas the owner never would have found on their own.
- **Proactive production awareness:** Production issues across 3-4 personal projects are detected, explained, and summarized with root cause and suggested fix — delivered within 15 minutes of occurrence.
- **Reduced operational overhead:** At least 3 previously-manual tasks fully automated, with the idea pipeline as the highest-priority candidate.

### Technical Success

- **24/7 reliability** with graceful degradation — if Claude API is unavailable, local Ollama handles fallback. No single point of failure kills the whole system.
- **Inference queuing is acceptable.** Batch workflows (trend analysis, log processing) can queue behind each other. No hard latency requirements for background pipelines.
- **Maintenance burden under 2 hours per week.** If the system becomes another thing to babysit, it has failed its own premise.

### Measurable Outcomes

| Metric | Target |
|--------|--------|
| Compelling ideas surfaced per month | ≥1 (worth a weekend prototype) |
| Production issue alert latency | ≤15 minutes |
| Personal projects monitored | 3-4 (Railway, Sentry, GCP sources) |
| Manual tasks automated | ≥3 |
| Monthly Claude API cost | <$50 |
| Weekly maintenance time | <2 hours |
| System uptime | 24/7 (tolerating planned maintenance windows) |

## User Journeys

### Journey 1: The Morning Digest (Passive Consumer)

It's 7:30 AM. Ducdo grabs coffee and checks his phone. Overnight, the homelab scraped HN, GitHub trending, and Reddit, clustered related signals, and scored opportunities against his skills and interests. An email lands in his inbox — a clean, scannable digest with three trend clusters. One scored high: a new real-time database gaining traction with no good SDK for his stack. He stars it as a weekend project candidate. Total time spent: 3 minutes. Without the system, he'd have missed it entirely.

**Phase:** Growth (Phase 4) | **Surface:** Email digest | **Device:** Mobile + Desktop

### Journey 2: The Production Alert (Reactive Responder)

It's 2 PM on a Tuesday. Ducdo gets an email alert: one of his Railway apps is throwing 500s. The email includes: what's failing (auth middleware timeout), probable root cause (upstream API latency spike), affected endpoints, and a suggested fix. He opens his laptop, applies the fix, and is done in 10 minutes. Without the system, he wouldn't have known until a user complained — then spent an hour reading logs.

**Phase:** Growth (Phase 5) | **Surface:** Email alert | **Device:** Mobile (triage) + Desktop (fix) | **SLA:** ≤15 minutes from incident to email

### Journey 3: The Pipeline Builder (Builder/Maintainer)

Ducdo wants to add expense tracking automation. He opens n8n via Tailscale on his desktop, creates a new workflow: email trigger → local AI extraction (Ollama) → structured output to spreadsheet. He tests with a sample receipt, tweaks the prompt, and it's live in 30 minutes. The pattern is familiar because it's the same architecture as every other pipeline on the box.

**Phase:** MVP (Phase 3) | **Surface:** n8n web UI | **Device:** Desktop only (n8n editor not mobile-friendly)

### Journey 4: The Knowledge Query (Knowledge Seeker)

Ducdo remembers the system flagged something about a WebSocket library two weeks ago but can't remember the details. He queries the RAG layer: "WebSocket library trending last two weeks." Qdrant returns the original trend analysis, the scored opportunity, and related HN discussions — all indexed automatically. He gets his answer in seconds instead of digging through browser history.

**Phase:** Growth (Phase 6) | **Surface:** RAG query interface (TBD — simple web UI or API) | **Device:** Desktop + Mobile

### Journey 5: The System Admin (Maintenance Mode)

Sunday morning. Ducdo checks Grafana dashboards — CPU, RAM, GPU utilization, Docker container health, disk usage. Ollama's loaded model is eating 14GB RAM, leaving things tight. He swaps to a smaller quantized model for routine tasks and reserves the larger one for scheduled deep-analysis jobs. He verifies Restic backups ran successfully. Total time: 20 minutes.

**Phase:** MVP (Phase 2) | **Surface:** Grafana dashboards, terminal/SSH | **Device:** Desktop (primary), Mobile (quick glance at Grafana)

### Journey 6: The Remote Check-in (Mobile/Tailscale)

Ducdo is at a coffee shop. He connects via Tailscale on his phone. Checks email for the morning digest, glances at Grafana for any red flags, sees the latest log monitor summary — all clear. He triggers a manual pipeline run by hitting an n8n webhook URL from his phone. Results will arrive by email when ready.

**Phase:** MVP (Phase 2 — Tailscale) | **Surface:** Email, Grafana (mobile-responsive), n8n webhooks | **Device:** Mobile

### Journey Requirements Summary

| Journey | Key Capabilities | Delivery Surface | Phase |
|---------|-----------------|------------------|-------|
| Morning Digest | Scheduled scraping, AI clustering/scoring, digest formatting | Email | Phase 4 |
| Production Alert | Log ingestion, AI triage, root cause analysis | Email (≤15 min) | Phase 5 |
| Pipeline Builder | n8n UI, Ollama API, reusable patterns | n8n web UI | Phase 3 |
| Knowledge Query | RAG search, Qdrant vector search, auto-indexing | Web UI / API (TBD) | Phase 6 |
| System Admin | Grafana dashboards, Docker mgmt, backup verification | Grafana, terminal | Phase 2 |
| Remote Check-in | Tailscale VPN, mobile-friendly access, webhook triggers | Email, Grafana, webhooks | Phase 2 |

## Innovation & Novel Patterns

### Detected Innovation Areas

- **Closed-Loop Intelligence Architecture:** The core innovation is the feedback loop where every service feeds signal into an AI intelligence layer, and the intelligence layer's outputs improve every service. Typical homelab stacks are collections of independent tools (Docker + reverse proxy + monitoring). This is an *integrated system* where the whole is greater than the sum of its parts. No existing turnkey solution implements this pattern for personal infrastructure.
- **Compounding Personal Knowledge System:** The strongest novel element. Unlike stateless automation that processes and forgets, the RAG layer (Qdrant + embeddings) indexes all system outputs — resolved incidents, trend analyses, automation results. The system accumulates intelligence over time, making each query and analysis incrementally more valuable.
- **Hybrid Local/Cloud AI Execution:** A pragmatic engineering decision rather than a breakthrough — but an important enabler. Local Ollama handles routine work (zero marginal cost, privacy), cloud Claude API handles complex reasoning. This makes the intelligence architecture economically viable (<$50/month).

### Validation Approach

- **Walking skeleton proves the pattern:** HN → Ollama summarization → email notification validates the integration layer end-to-end before building complexity.
- **Value is measurable:** Success criteria define concrete targets (ideas surfaced, alert latency, tasks automated). If the integrated system doesn't beat manual effort on these metrics, the innovation thesis fails.
- **Incremental validation:** Each phase adds a new intelligence capability. Value compounds but can be assessed at each phase boundary.

## Infrastructure Platform Requirements

### Technical Architecture

- **Primary language:** Go for custom services, scripts, and CLI tools. Single-binary deployment into Docker containers.
- **Orchestration:** Docker Compose for all service definitions, networking, and volume management. No Kubernetes — unnecessary complexity for a single-node setup.
- **Service communication:** Loosely coupled via HTTP/REST and webhooks. Each service owns its own data. No shared databases or volumes between services (exception: Qdrant serves as the shared knowledge store via API).
- **Reverse proxy:** Caddy for HTTPS termination, routing, and automatic TLS certificates for internal services.
- **Configuration:** Docker Compose files + environment variables. Service-specific config via mounted config files where needed.
- **Hybrid orchestration model:** n8n handles simple automations, prototyping, and visual workflow building. Core intelligence pipelines (trend analysis, log triage) are Go services that own their own scheduling (cron or lightweight job queue), retry logic, and completion tracking. n8n can trigger these services but does not own their lifecycle.

### Go Service Standards

Every custom Go service follows a consistent contract:

- **`/health` endpoint:** Returns up/down status for Docker health checks
- **`/status` endpoint:** Returns last run time, success/failure, error context, and run metadata — consumed by Grafana dashboards for pipeline health visibility
- **Shared `internal/` package:** Common clients for Ollama, Qdrant, email (SMTP), and structured logging configuration. No boilerplate duplication across services.
- **Structured logging to stdout:** All logs consumed by Loki via Docker log driver
- **Graceful shutdown:** Handle SIGTERM for clean Docker container stops

### Degraded Mode Operation

When internet connectivity is lost:

| Component | Degraded Behavior |
|-----------|-------------------|
| Ollama (local inference) | Fully operational — no external dependency |
| Grafana + Loki | Fully operational — local monitoring and logs |
| Gitea | Fully operational — local git hosting |
| n8n | Workflows not dependent on external APIs continue running |
| Qdrant | Fully operational — local vector search |
| Claude API pipelines | Graceful fallback to Ollama for reduced-quality inference |
| Trend scraping (HN/GitHub/Reddit) | Paused — resumes automatically on reconnection |
| Log drains (Railway/Sentry/GCP) | Paused — external sources unavailable |
| Email delivery | Queued — delivered on reconnection (max 72-hour retention) |

### Documentation & Runbooks

Detailed runbooks for each service and pipeline covering setup, maintenance, troubleshooting, backup/restore, and pipeline creation patterns. **Runbooks ship with each phase** — Phase 2 runbooks are part of the Phase 2 definition of done. No deferred documentation.

### Implementation Considerations

- **n8n for prototyping:** Use n8n to quickly prototype and validate new automation ideas before building dedicated Go services for critical pipelines.
- **Ollama API access:** All services interact with Ollama via its REST API. No direct GPU access outside the Ollama container.
- **Email delivery:** SMTP integration (self-hosted or external provider like Fastmail/Resend) for digest and alert delivery. Single email service used by all pipelines.

## Project Scoping & Phased Development

### MVP Strategy

**Approach:** Platform MVP — stand up the complete infrastructure foundation with all core services and prove the integration pattern with one end-to-end AI pipeline. The walking skeleton (HN → Ollama → email) validates the intelligence architecture on top of a fully operational platform.

**Resource Requirements:** Solo developer. All services are off-the-shelf Docker containers except custom Go glue services. The investment is in integration and configuration, not building from scratch.

### MVP Feature Set (Phases 1-3)

**Core User Journeys Supported:**
- Journey 3: Pipeline Builder (build and test automations via n8n)
- Journey 5: System Admin (monitor health via Grafana)
- Journey 6: Remote Check-in (access via Tailscale)

**Must-Have Capabilities:**

| Service | Purpose | MVP Role |
|---------|---------|----------|
| Fedora + Docker Compose | Base infrastructure | Foundation — everything runs on this |
| Caddy | Reverse proxy, HTTPS | Routing and TLS for all services |
| Ollama | Local AI inference | Core intelligence engine |
| Claude API | Cloud AI for complex reasoning | Hybrid AI — depth tasks |
| n8n | Workflow automation | Pipeline orchestration and prototyping |
| Grafana + Loki | Observability | Monitoring, dashboards, log aggregation |
| Qdrant | Vector search | Knowledge store (ready for Phase 6 RAG) |
| Gitea | Self-hosted git | Source control, local code hosting |
| Tailscale | Secure remote access | Mobile and remote connectivity |
| Restic | Backups | Data protection for all Docker volumes |
| Custom Go service | Walking skeleton | HN scraper → Ollama summarization → email digest |
| SMTP / Email | Notification delivery | Digest and alert emails |

**Walking Skeleton Milestone:** One Go service scrapes HN top stories daily, sends them to Ollama for summarization and clustering, and emails a formatted digest. This proves: Docker networking, Ollama API integration, Go service pattern, email delivery, and scheduled execution — the complete integration pattern.

### Post-MVP Features

**Phase 4 — Idea Generation:**
- Full daily pipeline: HN + GitHub trending + Reddit
- AI clustering across sources, opportunity scoring against owner's skills/interests
- Morning digest email with scored ideas, supporting evidence, competitive gaps

**Phase 5 — AI Log Monitor:**
- Log ingestion from Railway (log drains), Sentry (webhooks), GCP (Cloud Logging export)
- AI anomaly detection and root cause analysis via Ollama/Claude
- Alert emails with explanation and suggested fix within ≤15 minutes
- Coverage for 3-4 personal projects

**Phase 6 — Knowledge Layer:**
- RAG pipeline: embeddings + Qdrant indexing of all system outputs
- Queryable knowledge base (resolved incidents, trend analyses, automation results)
- Temporal metadata for freshness-aware search
- Query interface (web UI or API — TBD)

**Phase 7 — Life Automation:**
- Voice notes pipeline (Whisper + Syncthing)
- Expense/invoice automation
- Platform cost & uptime monitoring (Railway, GCP, Sentry)
- Meeting prep bot
- Bookmark rescue → RAG indexing

**Phase 8 — Dev Infrastructure:**
- CI/CD pipelines
- Containerized dev environments

## Risks & Mitigation

### Technical Risks

- **32GB RAM is tight:** Budget memory carefully across containers. Monitor via Grafana. 64GB upgrade is the near-term escape valve.
- **GPU single-inference bottleneck:** Acceptable for solo use. Batch pipelines queue; no hard latency requirements. Production alerts may need priority handling in Phase 5.
- **Storage accumulation:** Second NVMe SSD recommended for data (logs, vectors, models). Keep OS drive lean.
- **AI quality for critical tasks:** Fallback from Claude to Ollama ensures degraded-but-functional operation. Log triage quality can be validated against known incidents before going live.
- **Knowledge base freshness:** Qdrant embeddings must include timestamp metadata in payloads. Queries filter or boost by recency at search time. Consider TTL-based re-indexing for time-sensitive data (trends, incidents) vs. evergreen knowledge (project docs, resolved patterns).

### Integration Risks

- **Service sprawl in MVP:** 9+ services to stand up at once. Mitigated by Docker Compose (declarative, reproducible) and phased bring-up within MVP (start with Caddy + Ollama, add services incrementally).
- **Walking skeleton must work first:** If the end-to-end pattern doesn't work with one pipeline, don't add more. Validate before expanding.
- **Integration complexity:** Mitigated by Docker containerization, walking skeleton approach, and phased rollout. Each service is independently deployable.

### Operational Risks

- **Maintenance burden:** Target <2 hours/week. If exceeded, the project has failed its own premise. Runbooks ship with each phase.
- **Single point of failure:** The physical machine. Restic backups to off-machine storage are essential from day one. Recovery runbook must exist before Phase 2 is complete.

## Functional Requirements

### Infrastructure & Platform Management

- FR1: Owner can deploy all services via a single Docker Compose configuration
- FR2: Owner can access all web-based services through Caddy reverse proxy with HTTPS
- FR3: Owner can access the homelab remotely from any device via Tailscale VPN
- FR4: Owner can monitor system resource utilization (CPU, RAM, GPU, disk) via Grafana dashboards
- FR5: Owner can view Docker container health and status via Grafana
- FR6: Owner can perform automated backups of all Docker volumes and configurations via Restic
- FR7: Owner can restore from backups to recover the system after failure
- FR8: Owner can manage Git repositories locally via Gitea

### AI Inference & Routing

- FR9: Owner can run local AI inference (summarization, classification, embeddings) via Ollama
- FR10: Owner can route complex reasoning tasks to Claude API
- FR11: System can fall back to local Ollama inference when Claude API is unavailable
- FR12: Owner can swap Ollama models (size/type) based on workload and resource constraints
- FR13: System can route AI inference requests to the appropriate engine (local Ollama or cloud Claude) based on task type, ensuring consistent routing logic across all pipelines

### Workflow Automation

- FR14: Owner can create, edit, and test automation workflows via n8n web UI
- FR15: Owner can trigger workflows manually via webhook URLs
- FR16: System can execute scheduled workflows on defined intervals (cron-based)
- FR17: n8n workflows can call Ollama and Claude API for AI-powered processing steps

### Trend Analysis & Idea Generation

- FR18: System can scrape content from Hacker News, GitHub trending, and Reddit on a scheduled basis
- FR19: System can identify and group thematically related items across different sources into clusters using AI analysis
- FR20: System can score opportunities against owner's skills and interests
- FR21: System can generate and deliver a formatted morning digest email with scored ideas, supporting evidence, and competitive gaps
- FR22: Owner can trigger a manual idea pipeline run with a custom topic

### Production Monitoring & Alerting

- FR23: System can ingest production logs from Railway via log drains
- FR24: System can ingest events from Sentry via webhooks
- FR25: System can ingest logs from GCP via Cloud Logging export
- FR26: System can perform AI-powered anomaly detection on ingested logs
- FR27: System can generate root cause analysis and suggested fixes for detected issues
- FR28: System can deliver alert emails with incident explanation within 15 minutes of occurrence
- FR29: Owner can view aggregated logs from all sources via Grafana + Loki

### Knowledge Management

- FR30: System can generate embeddings from all system outputs (trend analyses, incident reports, automation results)
- FR31: System can index embeddings in Qdrant with source metadata and timestamps
- FR32: Owner can query the knowledge base with natural language and receive relevant results
- FR33: System can filter or boost search results by recency to prevent stale knowledge from dominating

### Notification & Delivery

- FR34: System can send formatted emails (digests, alerts, summaries) via SMTP
- FR35: Owner can receive all system outputs (digests, alerts, summaries) via email on both mobile and desktop
- FR36: System can queue email delivery when internet connectivity is lost and deliver on reconnection, with a maximum retention of 72 hours (older queued items discarded to prevent alert flooding)

### Observability & Operations

- FR37: All custom Go services expose `/health` endpoints for Docker health checks
- FR38: All custom Go services expose `/status` endpoints reporting last run time, success/failure, and error context
- FR39: System can aggregate structured logs from all services via Loki
- FR40: Owner can view pipeline execution health and history via Grafana dashboards

### Degraded Mode

- FR41: System can continue operating local services (Ollama, Grafana, Loki, Gitea, Qdrant, n8n) when internet is unavailable
- FR42: System can pause and automatically resume internet-dependent pipelines (scraping, log drains, email) on reconnection

### Life Automation (Phase 7 — Vision)

- FR43: System can transcribe voice recordings using Whisper and sync via Syncthing
- FR44: System can extract structured data (amounts, categories, dates) from receipts and invoices received via email
- FR45: System can monitor platform costs and uptime across Railway, GCP, and Sentry
- FR46: System can generate meeting preparation briefings from calendar, repos, and relevant docs
- FR47: System can scrape, summarize, and index saved bookmarks into the knowledge base

## Non-Functional Requirements

### Performance

- NFR1: Local Ollama inference for summarization tasks (8B models) completes within 30 seconds per request
- NFR2: Production alert pipeline (log ingestion → AI triage → email) completes end-to-end within 15 minutes
- NFR3: Qdrant vector search queries return results within 5 seconds
- NFR4: Grafana dashboards load within 10 seconds
- NFR5: System operates within 32GB RAM budget across all containers, with per-service memory limits enforced via Docker

### Security

- NFR6: All service web UIs accessible only via Tailscale VPN — no public-facing ports except Caddy (if needed for webhooks)
- NFR7: API keys (Claude, external services) stored as Docker secrets or environment variables, never hardcoded in source
- NFR8: Restic backups encrypted at rest
- NFR9: Gitea repositories require authentication for push/pull operations
- NFR10: Webhook endpoints (for log drains, Sentry) validate request signatures where supported

### Reliability

- NFR11: System achieves 24/7 uptime with tolerance for planned maintenance windows (monthly)
- NFR12: All Docker containers restart automatically on failure (restart policy: unless-stopped)
- NFR13: Restic backups run daily with at least 7 days of retention
- NFR14: System continues operating core local services during internet outages (see Degraded Mode Operation table)
- NFR15: No single service failure cascades to take down unrelated services

### Integration

- NFR16: All external API integrations (HN, GitHub, Reddit, Railway, Sentry, GCP) handle rate limits gracefully with exponential backoff
- NFR17: External API failures do not block unrelated pipelines — each pipeline operates independently
- NFR18: SMTP email delivery supports TLS encryption
- NFR19: All custom Go services produce structured JSON logs compatible with Loki ingestion

### Maintainability

- NFR20: Total weekly maintenance effort remains under 2 hours
- NFR21: Adding a new automation pipeline follows a documented pattern and is achievable within 1 hour for simple cases
- NFR22: All services updatable independently via Docker image pulls without rebuilding the entire stack
- NFR23: Docker Compose configuration version-controlled in Gitea
