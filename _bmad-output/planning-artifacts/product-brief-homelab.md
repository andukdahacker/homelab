---
title: "Product Brief: Homelab AI Dev Server"
status: "complete"
created: "2026-03-27"
updated: "2026-03-27"
inputs: ["user interview", "web research"]
---

# Product Brief: Homelab AI Dev Server

## Executive Summary

This is a personal, always-on AI development server built on consumer hardware (Ryzen 9950X, RTX 5060 16GB, 32GB RAM, 1TB SSD) running Fedora. It combines self-hosted dev infrastructure, hybrid AI inference (local Ollama + cloud Claude), workflow automation, and intelligent monitoring into a single machine that actively works for its owner — even while sleeping.

The core design principle: **infrastructure that thinks.** Every service on this box feeds signal into an intelligence layer, and the intelligence layer improves every service. If a component doesn't feed or consume the intelligence layer, it doesn't belong on this machine. The infrastructure exists to serve the intelligence, not the other way around.

## The Problem

Solo developers drown in operational overhead that steals time from building. Concretely:

- **Trend monitoring is manual.** You scan Hacker News, GitHub trending, and Reddit when you remember to. Patterns and opportunities slip by because no one is connecting dots across sources consistently. Last week's trending API could have been this month's side project — but you missed it.
- **Production issues are reactive.** Logs pile up unread. When something breaks, you context-switch into detective mode — reading logs, googling errors, piecing together root causes. Hours lost to triage that a summarizer could handle in seconds.
- **Repetitive tasks steal focus.** Health checks, deployment scripts, data processing, routine maintenance — tasks you've done a dozen times but never automated because the setup cost felt too high.
- **Cloud AI costs add up and create dependency.** Per-token API costs are unpredictable, and relying entirely on cloud services means your tools disappear if the service changes, you lose connectivity, or you need to process sensitive/proprietary code.

## The Solution

An 8-phase deployment that builds from bare metal to an intelligent dev companion:

**Foundation (Phases 1-2):** Docker-based infrastructure on Fedora with Caddy as reverse proxy. Core services include Gitea (source control), n8n (automation), Grafana + Loki (observability), and Qdrant (vector search). Hybrid AI layer pairs Ollama for local inference (privacy, speed, zero marginal cost) with Claude API for complex reasoning tasks.

**Intelligence Layer (Phases 3-5) — the core value:**

- **Automation Engine (Phase 3):** n8n pipelines that integrate AI processing into workflows — from simple notifications to complex multi-step automations that would otherwise require manual intervention.
- **Idea Generator (Phase 4):** Daily automated pipeline that scrapes Hacker News, GitHub trending, and Reddit, then uses AI to cluster related trends across sources and propose specific product ideas connected to the owner's skills and interests. Output: a morning digest with scored opportunities, supporting evidence, and competitive gaps. Nothing like this exists as a turnkey solution today.
- **AI Log Monitor (Phase 5):** Automated ingestion of production logs from Railway (log drains), Sentry (webhooks/API), and Google Cloud (Cloud Logging export). AI performs anomaly detection, root cause analysis, and fix suggestions — delivered before you even know something's wrong. Turns reactive debugging into proactive awareness.
- **Knowledge Layer (Phase 6):** RAG pipeline with Qdrant and embeddings that indexes everything the system processes — resolved incidents, trend analyses, automated outputs, and curated knowledge. This is what makes the system compound in value over time rather than just accumulate data.

**Life Automation (Phase 7) — reducing mental load beyond code:**

- **Voice Notes Pipeline:** Whisper (speech-to-text) + Syncthing. Record voice memos on your phone, they sync to the server, get transcribed, AI-summarized, and routed into the knowledge base. Capture ideas without typing.
- **Expense/Invoice Automation:** n8n ingests receipts and invoices from email, local AI extracts amounts/categories/dates, pushes structured data to a spreadsheet or database. No more manual bookkeeping.
- **Platform Cost & Uptime Monitor:** Polls Railway, GCP, and Sentry APIs to track spending trends and service health. Alerts on cost spikes or degradation before they become problems. "Your Railway app X burned 40% more compute this week — here's why."
- **Meeting Prep Bot:** Pulls your calendar, gathers context from relevant repos/emails/docs, generates a briefing doc before each meeting. Walk in prepared without the prep work.
- **Bookmark Rescue:** Periodically scrapes your saved bookmarks and open tab exports, summarizes content, and indexes into the RAG knowledge base. Turns years of digital hoarding into searchable, queryable knowledge.

**Supporting Infrastructure (Phase 8):** CI/CD pipelines with containerized dev environments, Tailscale (secure remote access), and Restic (backups).

The server works while you sleep — batch-processing logs overnight, pulling and summarizing trends before you wake up, transcribing your voice notes, and pre-warming context for your morning workflow.

## Hybrid AI Architecture

The local/cloud split is a deliberate architectural decision, not a compromise:

| Task Type | Target | Rationale |
|-----------|--------|-----------|
| Summarization, classification, embeddings | Ollama (local 8B models) | Zero marginal cost, fast, private |
| Log triage, routine analysis | Ollama (local 14B models) | Sensitive data stays local |
| Idea synthesis, deep reasoning, complex analysis | Claude API (cloud) | Quality matters more than cost here |
| Fallback when cloud unavailable | Ollama (local) | Graceful degradation, never fully offline |

**Cost target:** Keep Claude API usage under a reasonable monthly budget by routing aggressively to local models for routine work. The GPU pays for itself by handling the volume; Claude handles the depth.

## Technical Approach

- **Hardware:** Ryzen 9950X (16 cores), RTX 5060 16GB GDDR7, 32GB RAM, 1TB NVMe SSD (OS/apps) + additional NVMe SSD recommended for data (logs, vectors, models)
- **OS:** Fedora (bare metal, no hypervisor — avoids GPU passthrough headaches)
- **Containerized:** Everything runs in Docker for reproducibility and isolation, avoiding the config drift that plagues long-running homelabs
- **RTX 5060 capability:** 16GB VRAM supports quantized 8-14B parameter models at ~227 tokens/sec (single inference), sufficient for the automation and monitoring workloads
- **Backups:** Restic for automated snapshots of Docker volumes and configs to off-machine storage — the "second brain" vision only works if the data is protected

## Success Criteria

This is working when:

1. **The idea pipeline surfaces at least one compelling product idea per month** — "compelling" means an idea you'd spend a weekend prototyping, with supporting evidence from multiple sources.
2. **Production issues are explained before you investigate** — you wake up to a summary that says what happened, why, and what to do about it.
3. **At least 3 previously-manual tasks are fully automated** — candidates: deployment health checks, expense tracking, platform cost monitoring, meeting prep, bookmark processing, backup verification.
4. **The system runs reliably 24/7** with minimal maintenance overhead — it should reduce your workload, not become another thing to babysit.
5. **The maintenance burden stays under 2 hours per week** — if you're spending more time maintaining than saving, the project has failed its own premise.

## Scope

**In for v1 (Phases 1-6):**
- Base infrastructure with Docker, Caddy, core services
- Ollama + Claude hybrid AI layer
- n8n automation engine with AI-powered pipelines
- Daily idea generation from HN/GitHub/Reddit
- AI-powered log monitoring (Railway log drains, Sentry webhooks, GCP Cloud Logging export)
- Knowledge indexing / RAG with Qdrant — the compounding intelligence layer
- Restic backups (pulled forward from Phase 8 — essential for data protection)
- Tailscale (pulled forward from Phase 8 — enables remote access from day one)

**Phase 7 — Life Automation (after core intelligence layer is proven):**
- Voice notes pipeline (Whisper + Syncthing)
- Expense/invoice automation
- Platform cost & uptime monitoring (Railway, GCP, Sentry)
- Meeting/calendar prep bot
- Bookmark rescue → RAG indexing

**Deferred (no upstream dependencies):**
- Phase 8 (Full CI/CD and containerized dev envs) — can use GitHub/external CI initially
- NAS / media server (Jellyfin) — separate hardware, separate project

## Risks & Constraints

- **32GB RAM is tight.** Ollama can consume 10-16GB for a loaded model. Services need careful memory budgeting; 64GB is a likely near-term upgrade.
- **Storage strategy needed.** AI models (~50-100GB), Docker images, logs, and vector data accumulate fast. Recommended: add a second NVMe SSD (1-2TB) dedicated to data, keeping the OS drive lean. HDDs are only worth it for bulk media (future Jellyfin NAS).
- **GPU serves one inference at a time.** Concurrent requests queue. Acceptable for a solo setup, but pipeline design should account for this.
- **Maintenance burden.** Fedora + Docker + Ollama + monitoring is a real ops surface. The walking skeleton approach (see below) mitigates this by delivering value before complexity accumulates.

## Implementation Strategy

**Walking skeleton first:** Before building all 8 phases linearly, get the thinnest possible end-to-end pipeline working: one data source (HN) → one AI analysis (Ollama summarization) → one notification (email or webhook). Prove the pattern works, then widen to multiple sources and deeper analysis.

**Phase 1 milestone (one weekend):** Fedora installed, Docker running, Ollama serving a model, one n8n workflow summarizing HN top stories daily. Ship something before architecting everything.

## Vision

In 6-12 months, this server becomes a genuine development companion — not just hosting services, but actively contributing to decision-making. The knowledge base grows as the RAG layer indexes processed trends, resolved incidents, and automated outputs. The idea generator refines its signal. The log monitor builds pattern recognition across incidents.

The long-term aspiration: a personal AI infrastructure that compounds in value the longer it runs — where every log analyzed, every trend tracked, and every automation built makes the next one smarter and faster. Eventually, the server doesn't just respond to your work — it anticipates it.
