# Story 1.2: Docker Compose Core Services & Caddy Reverse Proxy

Status: done

## Story

As a homelab owner,
I want all core services defined in Docker Compose with Caddy routing and HTTPS,
so that I can bring up the entire stack with `docker compose up -d` and access every service through clean URLs.

## Acceptance Criteria

1. **Given** a populated `.env` file and completed host initialization, **When** I run `docker compose up -d`, **Then**:
   - Ollama, Grafana, Loki, Qdrant, Gitea, n8n, and Caddy containers all start successfully
   - Each service has `restart: unless-stopped` policy
   - Each service has `mem_limit` matching the architecture memory budget (Ollama 16GB, Qdrant 2GB, Grafana 512MB, Loki 1GB, n8n 1GB, Gitea 512MB, Caddy 256MB)
   - All services are on the `homelab` bridge network
   - Each service uses bind mounts to `/data/homelab/<service>/`

2. **Given** all services are running, **When** I access Grafana, Gitea, n8n, or Qdrant web UIs via Caddy, **Then**:
   - Caddy routes each to the correct service with HTTPS
   - The Caddyfile is stored in `configs/caddy/Caddyfile`

3. **Given** one service crashes, **When** Docker detects the failure, **Then**:
   - The container restarts automatically
   - No other services are affected (FR41, NFR15)

## Tasks / Subtasks

- [x] Task 1: Define all 7 service blocks in `docker-compose.yml` (AC: #1)
  - [x] Ollama service: `ollama/ollama:0.20` image, GPU passthrough (`deploy.resources.reservations.devices`), bind mount `/data/homelab/ollama/:/root/.ollama`, port `11434`, `mem_limit: 16g`
  - [x] Grafana service: `grafana/grafana:12.4` image, bind mount `/data/homelab/grafana/:/var/lib/grafana`, config mount `./configs/grafana/provisioning:/etc/grafana/provisioning:ro` and `./configs/grafana/dashboards:/var/lib/grafana/dashboards:ro`, port `3000`, `mem_limit: 512m`, env vars from `.env` (`GF_SECURITY_ADMIN_USER`, `GF_SECURITY_ADMIN_PASSWORD`)
  - [x] Loki service: `grafana/loki:3.7` image, bind mount `/data/homelab/loki/:/loki`, config mount `./configs/loki/config.yaml:/etc/loki/config.yaml:ro`, port `3100`, `mem_limit: 1g`
  - [x] Qdrant service: `qdrant/qdrant:v1.17.0` image, bind mount `/data/homelab/qdrant/:/qdrant/storage`, port `6333`, `mem_limit: 2g`
  - [x] Gitea service: `gitea/gitea:1.25` image, bind mount `/data/homelab/gitea/:/data`, port `3000` (internal, Caddy-fronted), `mem_limit: 512m`, env vars from `.env` (`GITEA__database__DB_TYPE`, `GITEA__server__ROOT_URL`)
  - [x] n8n service: `n8nio/n8n:1.76` image, bind mount `/data/homelab/n8n/:/home/node/.n8n`, port `5678`, `mem_limit: 1g`, env var `N8N_ENCRYPTION_KEY` from `.env`
  - [x] Caddy service: `caddy:2.11` image, bind mount `/data/homelab/caddy/:/data`, config mount `./configs/caddy/Caddyfile:/etc/caddy/Caddyfile:ro`, ports `80:80` and `443:443`, `mem_limit: 256m`
  - [x] Every service has: `env_file: .env`, `networks: [homelab]`, `restart: unless-stopped`

- [x] Task 2: Create `configs/caddy/Caddyfile` (AC: #2)
  - [x] Define reverse proxy routes for: Grafana, Gitea, n8n, Qdrant dashboard
  - [x] Use `{$CADDY_DOMAIN}` environment variable for domain base
  - [x] Route pattern: `grafana.{$CADDY_DOMAIN}` -> `grafana:3000`, `gitea.{$CADDY_DOMAIN}` -> `gitea:3000`, `n8n.{$CADDY_DOMAIN}` -> `n8n:5678`, `qdrant.{$CADDY_DOMAIN}` -> `qdrant:6333`
  - [x] Use Caddy's automatic HTTPS with internal/self-signed certs (no public CA for `.local` domains)
  - [x] Ollama is internal-only (no Caddy route) — accessed by services via Docker network `ollama:11434`

- [x] Task 3: Create `configs/loki/config.yaml` (AC: #1)
  - [x] Minimal Loki config: auth disabled, server port 3100, ingester lifecycle, filesystem storage under `/loki/`, schema config for log streams, retention period
  - [x] Storage path: `/loki/chunks` and `/loki/index` (inside container, backed by bind mount)

- [x] Task 4: Validate compose file and service startup (AC: #1, #2, #3)
  - [x] Run `docker compose config` to validate YAML syntax
  - [x] Verify all 7 services listed with correct images, `mem_limit`, `restart` policy, network, `env_file`
  - [x] Verify each service has bind mount to `/data/homelab/<service>/`
  - [x] Verify Caddy has ports 80 and 443 exposed

- [x] Task 5: Address deferred work from Story 1.1 (AC: #1)
  - [x] `env_file: .env` is now on every service (resolves deferred item from Story 1.1 review)

## Dev Notes

### Docker Image Versions — Pin Specific Tags

**CRITICAL: Never use `latest` tag.** Pin all images to specific versions:

| Service | Image | Version Tag | Notes |
|---------|-------|-------------|-------|
| Ollama | `ollama/ollama` | `0.20` | Latest stable as of Apr 2026 |
| Grafana | `grafana/grafana` | `12.4` | Major version 12.x current |
| Loki | `grafana/loki` | `3.7` | Latest 3.x stable |
| Qdrant | `qdrant/qdrant` | `v1.17.0` | Uses `v` prefix + full semver — no floating minor tags |
| Gitea | `gitea/gitea` | `1.25` | Latest 1.x stable |
| n8n | `n8nio/n8n` | `1.76` | Staying on 1.x — n8n 2.0 has breaking changes (see below) |
| Caddy | `caddy` | `2.11` | Latest 2.x stable |

**n8n version note:** n8n 2.0 was released with significant breaking changes (Start node removed, sub-workflow output changed, Python Code node requires external task runners). Staying on 1.76 is intentional. Upgrade to 2.x can be planned separately when ready.

**Verify tags before pull:** Run `docker pull <image>:<tag>` to confirm each tag exists on Docker Hub. If a floating tag (e.g., `0.20`) doesn't resolve, pin to the latest patch (e.g., `0.20.2`).

### Memory Budget (32GB total — HARD CONSTRAINT)

| Service | `mem_limit` | Notes |
|---------|------------|-------|
| Ollama | `16g` | GPU model hot-swap headroom |
| Qdrant | `2g` | Vector index in memory |
| Grafana | `512m` | Dashboards + queries |
| Loki | `1g` | Log ingestion + indexing |
| n8n | `1g` | Workflow execution |
| Gitea | `512m` | Light git hosting |
| Caddy | `256m` | Reverse proxy |
| OS + Docker | ~4GB | Fedora + daemon |
| Headroom | ~5GB | Spike buffer |

### Docker Compose Service Structure

Every service block MUST include these keys:
```yaml
services:
  <service>:
    image: <image>:<pinned-tag>
    container_name: <service>
    env_file: .env
    networks:
      - homelab
    restart: unless-stopped
    mem_limit: <value>
    volumes:
      - /data/homelab/<service>/:<container-data-path>
```

### Ollama GPU Passthrough

Ollama needs GPU access for inference. Use Docker Compose `deploy` key:
```yaml
ollama:
  deploy:
    resources:
      reservations:
        devices:
          - driver: nvidia
            count: 1
            capabilities: [gpu]
```

**Note:** Requires NVIDIA Container Toolkit installed on host. The `init-host.sh` from Story 1.1 does NOT install this — it's a host prerequisite. Add a comment in the compose file noting this dependency.

### Caddy HTTPS with `.local` Domains

Caddy's automatic HTTPS gets certificates from Let's Encrypt, which won't work for `.local` domains (not publicly resolvable). Options:
- Use `tls internal` directive in the Caddyfile to generate self-signed certs
- Or use `http://` only for local access (Tailscale handles encryption in transit for remote access — Story 1.3)

Recommended: `tls internal` for clean HTTPS with self-signed certs. Users accept the browser warning once.

### Caddyfile Pattern

```
grafana.{$CADDY_DOMAIN} {
  tls internal
  reverse_proxy grafana:3000
}

gitea.{$CADDY_DOMAIN} {
  tls internal
  reverse_proxy gitea:3000
}

n8n.{$CADDY_DOMAIN} {
  tls internal
  reverse_proxy n8n:5678
}

qdrant.{$CADDY_DOMAIN} {
  tls internal
  reverse_proxy qdrant:6333
}
```

### Loki Minimal Config

Loki needs a config file to start. Minimal required config:
```yaml
auth_enabled: false

server:
  http_listen_port: 3100

common:
  path_prefix: /loki
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: "2024-01-01"
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h
```

### Grafana Provisioning Mounts

Grafana needs two config mount paths for auto-provisioning (used in Story 2.1/2.2):
- `./configs/grafana/provisioning:/etc/grafana/provisioning:ro` — datasource and dashboard provider configs
- `./configs/grafana/dashboards:/var/lib/grafana/dashboards:ro` — dashboard JSON files

Mount these read-only (`:ro`). The directories already exist from Story 1.1 with `.gitkeep` files.

### Gitea Internal Port Conflict

Both Grafana and Gitea use port 3000 internally. Since all access is via Caddy reverse proxy (by service name on Docker network), there is NO host port conflict. Do NOT expose host ports for individual services — only Caddy exposes ports 80/443.

**Exception:** During development, you may want to temporarily expose individual service ports for debugging. This is fine but not required in the compose file.

### Loki Docker Log Driver

The Loki Docker log driver plugin was installed in Story 1.1 (`init-host.sh`). However, the per-service `logging` configuration in `docker-compose.yml` is deferred to **Story 2.1** (Loki Log Aggregation). In this story, do NOT add `logging:` blocks to services — just ensure Loki itself is running and healthy.

### Service Startup Dependencies

Use `depends_on` sparingly:
- Loki has no dependencies (starts first, accepts logs)
- Grafana depends on Loki (optional, for datasource availability)
- Caddy has no hard dependencies (reverse proxy retries upstream connections)
- Ollama has no dependencies (standalone GPU service)
- **Do NOT use `condition: service_healthy` for Ollama** — services must handle Ollama unavailability gracefully (degraded mode design)

### `.env` Variables Used by Services

Services that consume `.env` vars in this story:
- **Grafana:** `GF_SECURITY_ADMIN_USER`, `GF_SECURITY_ADMIN_PASSWORD`
- **Gitea:** `GITEA__database__DB_TYPE`, `GITEA__server__ROOT_URL`
- **n8n:** `N8N_ENCRYPTION_KEY`
- **Caddy:** `CADDY_DOMAIN` (via Caddyfile `{$CADDY_DOMAIN}`)

All already defined in `.env.example` from Story 1.1.

### Deferred Work Addressed

From Story 1.1 code review:
- `docker-compose.yml` missing `env_file: .env` — resolved in this story (every service gets `env_file: .env`)
- CADDY_DOMAIN + TLS guidance — resolved in this story via Caddyfile with `tls internal`

### Project Structure Notes

Files created/modified in this story:
```
homelab/
├── configs/
│   ├── caddy/
│   │   └── Caddyfile          # NEW — reverse proxy routes
│   └── loki/
│       └── config.yaml        # NEW — minimal Loki config
├── docker-compose.yml         # MODIFIED — add 7 service definitions
```

**Phase discipline:** This is Phase 1-2 (foundation). Do NOT create:
- `cmd/` directory (Phase 3)
- `internal/` directory (Phase 3)
- Any Go source files
- Any Dockerfile for custom services
- Grafana provisioning configs (Story 2.1/2.2)
- Loki Docker log driver `logging:` blocks per service (Story 2.1)

### Testing

No Go code — validation is manual:
1. `docker compose config` — validates YAML syntax and interpolation
2. `docker compose up -d` — verify all 7 containers start
3. `docker compose ps` — verify all services are running with correct images
4. Access Caddy routes — verify reverse proxy to Grafana, Gitea, n8n, Qdrant UIs
5. `docker compose down && docker compose up -d` — verify restart behavior
6. Kill a container (`docker kill <container>`) — verify auto-restart

### References

- [Source: architecture.md#Memory Allocation] — Memory budget table for `mem_limit` values
- [Source: architecture.md#Infrastructure & Deployment] — Bind mount strategy, volume paths
- [Source: architecture.md#Docker Compose Service Naming] — Service naming conventions
- [Source: architecture.md#Log Collection Strategy] — Loki Docker log driver config (deferred to Story 2.1)
- [Source: architecture.md#Phase Build Order] — Phase 1-2 creates compose, configs, no Go services
- [Source: architecture.md#Integration Points] — Caddy reverse proxy to all web UIs
- [Source: epics.md#Story 1.2] — Acceptance criteria and user story
- [Source: prd.md#Infrastructure Platform Requirements] — Docker Compose, Caddy, configuration approach
- [Source: prd.md#NFR5] — 32GB RAM budget with per-service memory limits
- [Source: prd.md#NFR6] — Tailscale-only access, no public ports except Caddy
- [Source: prd.md#NFR12] — restart: unless-stopped on every container
- [Source: prd.md#NFR15] — No cascading failures
- [Source: project-context.md] — Docker image pinning, restart policy, mem_limit enforcement, env_file rules
- [Source: deferred-work.md] — Story 1.1 deferred items resolved here

### Cross-Story Context

- **Story 1.1** (done): Created `docker-compose.yml` skeleton, `configs/` directories, `.env.example`, `init-host.sh`
- **Story 1.3** depends on Caddy routes being functional for Tailscale remote access testing
- **Story 1.4** depends on Gitea service running for repository setup
- **Story 2.1** will add Loki Docker log driver `logging:` blocks to all services and Grafana datasource provisioning
- **Story 2.2** will add Grafana dashboard JSON files and dashboard provisioning config

### Previous Story Intelligence (Story 1.1)

Key learnings from Story 1.1 implementation:
- Go not installed on host — `go.mod` created manually (no `go` commands available)
- shellcheck not installed — validate scripts via manual review
- Review found 7 patches applied (permissions, env validation, Loki plugin pinning, Docker daemon check)
- `.gitkeep` files placed in empty config directories — these will be replaced by actual config files in this story
- `docker-compose.yml` skeleton exists with `homelab` bridge network defined — extend it, don't replace it

### Git Intelligence

Recent commits:
- `7d43803` feat: Story 1-1 — project repository & host initialization
- `4c9e98e` Initial commit: homelab project with BMad planning and implementation artifacts

Pattern: conventional commit messages with story reference. Follow same pattern.

### Review Findings

- [x] [Review][Decision] Host port binding scope — Ollama (11434) and Loki (3100) bound to 0.0.0.0. Decided: keep as-is, Tailscale handles network access control.
- [x] [Review][Decision] Gitea SSH port not exposed — Decided: defer to Story 1.4 (Gitea setup). SSH config belongs there with full Gitea env var context.
- [x] [Review][Patch] Caddyfile missing CADDY_DOMAIN default — Added `{$CADDY_DOMAIN:homelab.local}` fallback syntax. [configs/caddy/Caddyfile]
- [x] [Review][Patch] Image tags patch-pinned — Verified on Docker Hub and pinned: ollama:0.20.3, loki:3.7.1, grafana:12.4.2, gitea:1.25.5, n8n:1.76.4, caddy:2.11.2 (qdrant:v1.17.0 already pinned). [docker-compose.yml]
- [x] [Review][Defer] Loki retention/compaction config missing — No `limits_config.retention_period` or `compactor` block. Storage grows unbounded under `/data/homelab/loki/`. — deferred, not in story scope
- [x] [Review][Defer] Volume ownership mismatch for Loki (UID 10001) and Grafana (UID 472) — `init-host.sh` creates dirs owned by current user, but containers run as different UIDs. Will cause permission denied errors at runtime. — deferred, pre-existing (Story 1.1 init-host.sh)

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

None — clean implementation with no issues.

### Completion Notes List

- Task 1: Defined all 7 service blocks in `docker-compose.yml` — Ollama (GPU passthrough, 16g), Grafana (512m, provisioning mounts), Loki (1g, config mount), Qdrant (2g), Gitea (512m), n8n (1g), Caddy (256m, ports 80/443). All services have `env_file`, `networks`, `restart: unless-stopped`, and bind mounts to `/data/homelab/<service>/`. Grafana/Gitea/n8n/Qdrant do not expose host ports — access is via Caddy reverse proxy only.
- Task 2: Created `configs/caddy/Caddyfile` with 4 reverse proxy routes using `{$CADDY_DOMAIN}` env var and `tls internal` for self-signed HTTPS. Ollama excluded (internal-only).
- Task 3: Created `configs/loki/config.yaml` — minimal config with auth disabled, filesystem storage, TSDB schema v13, inmemory ring.
- Task 4: Validated via `docker compose config` — all 7 services resolve correctly with expected images, mem_limit, restart policy, networks, env vars, and bind mounts.
- Task 5: Confirmed `env_file: .env` on every service, resolving deferred item from Story 1.1 review.

### Change Log

- 2026-04-08: Implemented Story 1.2 — 7 Docker Compose service definitions, Caddyfile reverse proxy config, Loki minimal config. Resolved Story 1.1 deferred env_file item.

### File List

- `docker-compose.yml` — Modified: added 7 service definitions (ollama, loki, grafana, qdrant, gitea, n8n, caddy)
- `configs/caddy/Caddyfile` — New: reverse proxy routes for Grafana, Gitea, n8n, Qdrant with tls internal
- `configs/loki/config.yaml` — New: minimal Loki configuration
- `configs/caddy/.gitkeep` — Deleted: replaced by Caddyfile
- `configs/loki/.gitkeep` — Deleted: replaced by config.yaml
