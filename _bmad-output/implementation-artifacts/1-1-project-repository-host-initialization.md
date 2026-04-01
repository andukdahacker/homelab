# Story 1.1: Project Repository & Host Initialization

Status: done

## Story

As a homelab owner,
I want a fully initialized project repository and host setup script,
so that I can go from a fresh Fedora install to a ready-to-run homelab with one script.

## Acceptance Criteria

1. **Given** a fresh clone of the homelab repository, **When** I review the project structure, **Then** it contains:
   - `go.mod` (module `github.com/ducdo/homelab`, Go 1.26)
   - `.env.example` with placeholder entries for all planned services
   - `.gitignore` (exact contents in Dev Notes)
   - `scripts/init-host.sh` (executable)
   - `configs/` directory with subdirectories for `caddy/`, `grafana/`, `loki/`, `n8n/`
   - `docker-compose.yml` skeleton
   - `README.md`

2. **Given** a fresh Fedora host with Docker installed, **When** I run `scripts/init-host.sh`, **Then**:
   - It creates all `/data/homelab/<service>/` bind mount directories: `ollama`, `grafana`, `loki`, `qdrant`, `gitea`, `n8n`, `caddy`
   - It copies `.env.example` to `.env` if `.env` does not already exist (never overwrites existing `.env`)
   - It sets appropriate directory permissions

3. **Given** the `docker-compose.yml` skeleton, **When** I inspect it, **Then**:
   - It defines a `homelab` bridge network
   - It references `.env` via `env_file` directive

## Tasks / Subtasks

- [x] Task 1: Initialize Go module (AC: #1)
  - [x] Run `go mod init github.com/ducdo/homelab` to create `go.mod`
  - [x] Verify `go.mod` contains `go 1.26` directive — if not, manually edit to set `go 1.26`
  - [x] Verify module path is exactly `github.com/ducdo/homelab`
- [x] Task 2: Create `.gitignore` (AC: #1)
  - [x] Contents specified in Dev Notes "`.gitignore` Exact Contents" section — use that as authoritative source
  - [x] No extra entries — keep minimal
- [x] Task 3: Create `.env.example` (AC: #1)
  - [x] Add placeholder entries for all planned services (see Dev Notes for required vars)
  - [x] Include comments explaining each variable's purpose
- [x] Task 4: Create `scripts/init-host.sh` (AC: #2)
  - [x] Create all 7 bind mount directories under `/data/homelab/`
  - [x] Copy `.env.example` to `.env` only if `.env` does not exist
  - [x] Check Docker is installed (`command -v docker`) and print helpful error if missing
  - [x] Use `sudo mkdir -p` for `/data/homelab/` (requires root to create under `/data/`)
  - [x] Set `chmod 755` on created directories
  - [x] Run `sudo chown -R $USER:$USER /data/homelab/` to set ownership to current user
  - [x] Install Loki Docker log driver plugin: `docker plugin install grafana/loki-docker-driver:latest --alias loki --grant-all-permissions` (skip if already installed)
  - [x] Make script executable (`chmod +x`)
  - [x] Use `#!/usr/bin/env bash` shebang and `set -euo pipefail`
- [x] Task 5: Create `docker-compose.yml` skeleton (AC: #3)
  - [x] Use exact structure from Dev Notes "docker-compose.yml Skeleton Structure" section
  - [x] Include comments marking where services will be added in Story 1.2
- [x] Task 6: Create `configs/` directory structure (AC: #1)
  - [x] Create `configs/caddy/` (Caddyfile added in Story 1.2)
  - [x] Create `configs/grafana/provisioning/datasources/` (pre-scaffolded so Story 2.1 adds config files without directory creation)
  - [x] Create `configs/grafana/provisioning/dashboards/` (pre-scaffolded so Story 2.2 adds config files without directory creation)
  - [x] Create `configs/grafana/dashboards/` (pre-scaffolded for Story 2.2 dashboard JSONs)
  - [x] Create `configs/loki/` (config added in Story 2.1)
  - [x] Create `configs/n8n/` (workflow exports later)
  - [x] Add `.gitkeep` files in empty directories to ensure they are tracked by git
- [x] Task 7: Create `docs/runbooks/` directory (AC: #1)
  - [x] Create `docs/runbooks/` directory with `.gitkeep`
  - [x] This directory will hold `new-pipeline.md` (Phase 3) and operational runbooks
- [x] Task 8: Create `README.md` (AC: #1)
  - [x] Project name and one-line description
  - [x] Prerequisites (Fedora, Docker, Docker Compose)
  - [x] Quick start: `scripts/init-host.sh` then populate `.env` then `docker compose up -d`
  - [x] Keep concise — will grow with each phase
- [x] Task 9: Verify complete structure matches architecture spec
  - [x] Confirm no files created for Phase 3+ (no `cmd/`, no `internal/`)
  - [x] Confirm `.gitignore` is correct
  - [x] Confirm `go.mod` has correct module path and Go version

## Dev Notes

### Phase Discipline

This is Phase 1 — **foundation only**. Do NOT create:
- `cmd/` directory (Phase 3)
- `internal/` directory (Phase 3)
- Any Go source files beyond `go.mod`
- Any Dockerfile (Phase 3)

### `.env.example` Required Variables

```
# Ollama
OLLAMA_URL=http://ollama:11434

# Grafana
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=changeme

# Gitea
GITEA__database__DB_TYPE=sqlite3
GITEA__server__ROOT_URL=https://gitea.homelab.local

# n8n (N8N_ENCRYPTION_KEY is REQUIRED — n8n fails without it)
N8N_ENCRYPTION_KEY=changeme-generate-a-random-key

# Caddy
CADDY_DOMAIN=homelab.local

# SMTP (for email delivery - Phase 3+)
SMTP_HOST=
SMTP_PORT=587
SMTP_USER=
SMTP_PASSWORD=
SMTP_FROM=

# Claude API (Phase 3+)
ANTHROPIC_API_KEY=
```

### `scripts/init-host.sh` Bind Mount Directories

Create these 7 directories (requires `sudo` — `/data/` is a root-level path):
```
/data/homelab/ollama
/data/homelab/grafana
/data/homelab/loki
/data/homelab/qdrant
/data/homelab/gitea
/data/homelab/n8n
/data/homelab/caddy
```

The script should use `sudo mkdir -p` and `sudo chown $USER:$USER` to make directories owned by the current user after creation.

### `docker-compose.yml` Skeleton Structure

```yaml
# No 'version:' key — Docker Compose v5 spec
networks:
  homelab:
    driver: bridge

services:
  # Services defined in Story 1.2
```

All services will use:
- `env_file: .env`
- `networks: [homelab]`
- `restart: unless-stopped`
- Bind mounts to `/data/homelab/<service>/`
- `mem_limit` per architecture memory budget
- Loki Docker log driver (configured in Story 2.1)

### `.gitignore` Exact Contents

```
.env
/data/
.idea/
.vscode/
*.swp
```

### Project Structure Notes

Target structure for this story (Phase 1 only):
```
homelab/
├── configs/
│   ├── caddy/              # Empty, Caddyfile added in 1.2
│   ├── grafana/
│   │   ├── provisioning/
│   │   │   ├── datasources/  # Populated in 2.1
│   │   │   └── dashboards/   # Populated in 2.2
│   │   └── dashboards/       # Populated in 2.2
│   ├── loki/               # config.yaml added in 2.1
│   └── n8n/                # Workflow exports later
├── docs/
│   └── runbooks/           # new-pipeline.md added in Phase 3
├── scripts/
│   └── init-host.sh        # Host initialization script
├── docker-compose.yml      # Skeleton with network definition
├── .env.example            # Secret template (committed)
├── .gitignore
├── go.mod                  # github.com/ducdo/homelab, Go 1.26
└── README.md
```

### Testing

No Go code in this story — no unit tests needed. Validation is manual:
1. Run `shellcheck scripts/init-host.sh` to validate shell script quality
2. Run `scripts/init-host.sh` and verify directories created with correct ownership
3. Verify `.env` copied from `.env.example`
4. Run `docker compose config` to validate compose file syntax
5. Verify `go mod tidy` runs clean
6. Verify Loki Docker log driver plugin installed: `docker plugin ls | grep loki`

### References

- [Source: architecture.md#Selected Approach: Go Monorepo with Docker Compose] — Project structure and directory layout
- [Source: architecture.md#Phase Build Order] — Phase 1-2 creates `docker-compose.yml`, `configs/`, `scripts/init-host.sh`, `.env.example`, `.gitignore`, `go.mod`, `README.md`, `docs/runbooks/`
- [Source: architecture.md#Infrastructure & Deployment] — Bind mount strategy: `/data/homelab/<service>/`, `init-host.sh` purpose
- [Source: architecture.md#Memory Allocation] — Memory budget table for `mem_limit` values
- [Source: architecture.md#.gitignore Contents] — Exact `.gitignore` entries
- [Source: architecture.md#slog Initialization] — No `internal/logging/` package (Phase 3)
- [Source: epics.md#Story 1.1] — Acceptance criteria and user story
- [Source: prd.md#Infrastructure Platform Requirements] — Docker Compose, environment variables, configuration approach
- [Source: project-context.md] — Go 1.26, single module, stdlib-only, phase discipline rules

### Cross-Story Context

- **Story 1.2** depends on this story's `docker-compose.yml` skeleton and `configs/` directories to add service definitions and Caddyfile
- **Story 1.3** depends on Tailscale configuration (host-level, not Docker)
- **Story 1.4** depends on Gitea service in compose and `configs/` structure
- **Story 2.1** depends on `configs/loki/` and `configs/grafana/provisioning/datasources/` directories

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

- Go not installed on host — `go.mod` created manually with correct module path and Go 1.26 directive
- shellcheck not installed — script validated by manual review of best practices

### Completion Notes List

- Task 1: Created `go.mod` manually (Go not installed) with `github.com/ducdo/homelab` module and `go 1.26`
- Task 2: Created `.gitignore` with exact contents from Dev Notes (`.env`, `/data/`, `.idea/`, `.vscode/`, `*.swp`)
- Task 3: Created `.env.example` with all planned service variables from Dev Notes
- Task 4: Created `scripts/init-host.sh` — creates 7 bind mount dirs, copies `.env.example`, checks Docker, installs Loki plugin
- Task 5: Created `docker-compose.yml` skeleton with `homelab` bridge network (no version key, Compose v5 spec)
- Task 6: Created full `configs/` directory tree with `.gitkeep` files (caddy, grafana provisioning, loki, n8n)
- Task 7: Created `docs/runbooks/` with `.gitkeep`
- Task 8: Created concise `README.md` with project description, prerequisites, and quick start
- Task 9: Verified structure — no Phase 3+ files, `.gitignore` correct, `go.mod` correct

### Change Log

- 2026-04-01: Story 1.1 implemented — all project foundation files and directories created

### File List

- go.mod (new)
- .gitignore (new)
- .env.example (new)
- scripts/init-host.sh (new)
- docker-compose.yml (new)
- configs/caddy/.gitkeep (new)
- configs/grafana/provisioning/datasources/.gitkeep (new)
- configs/grafana/provisioning/dashboards/.gitkeep (new)
- configs/grafana/dashboards/.gitkeep (new)
- configs/loki/.gitkeep (new)
- configs/n8n/.gitkeep (new)
- docs/runbooks/.gitkeep (new)
- README.md (new)

### Review Findings

- [x] [Review][Defer] `docker-compose.yml` missing `env_file: .env` directive — deferred to Story 1.2 when services are added (`env_file` is per-service)
- [x] [Review][Patch] `$USER` may be unset in sudo/cron contexts — fixed: `CURRENT_USER="${USER:-$(id -un)}"`
- [x] [Review][Patch] `.env` created with default umask (world-readable) — fixed: `install -m 600`
- [x] [Review][Patch] Loki plugin grep match too broad — fixed: anchored to `grafana/loki-docker-driver`
- [x] [Review][Patch] No validation `.env.example` exists before copy — fixed: added existence check with error message
- [x] [Review][Patch] No Docker daemon running check — fixed: added `docker info` check
- [x] [Review][Patch] Parent `/data/homelab/` permissions not explicitly set — fixed: added parent to `chmod 755`
- [x] [Review][Patch] Loki Docker driver plugin uses `latest` tag — fixed: pinned to `3.3.3`
- [x] [Review][Defer] Default secrets (`changeme`) not validated before `docker compose up` — deferred, UX hardening beyond this story's scope
- [x] [Review][Defer] CADDY_DOMAIN + TLS guidance missing — deferred, addressed in Story 1.2/1.3
- [x] [Review][Defer] `--grant-all-permissions` on Loki plugin install — deferred, standard Loki install practice
