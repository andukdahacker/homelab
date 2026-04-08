# Deferred Work

## Deferred from: code review of 1-1-project-repository-host-initialization (2026-04-01)

- Default secrets (`changeme` for Grafana, `changeme-generate-a-random-key` for n8n) are copied verbatim into `.env` with no runtime validation — user must manually edit before `docker compose up`
- CADDY_DOMAIN defaults to `homelab.local` with no TLS guidance — Caddy/TLS configuration is Story 1.2/1.3
- `docker plugin install` uses `--grant-all-permissions` which blindly grants all plugin-requested permissions — standard for Loki driver install but worth revisiting if plugin scope changes
- `docker-compose.yml` missing `env_file: .env` directive — deferred to Story 1.2 when actual services are added (env_file is a per-service key)

## Deferred from: code review of 1-2-docker-compose-core-services-caddy-reverse-proxy (2026-04-08)

- Loki retention/compaction config missing — No `limits_config.retention_period` or `compactor` block in `configs/loki/config.yaml`. Storage grows unbounded under `/data/homelab/loki/`. Should be addressed when Loki log ingestion is fully configured (Story 2.1).
- Volume ownership mismatch — `init-host.sh` creates `/data/homelab/loki/` and `/data/homelab/grafana/` owned by current user, but Loki runs as UID 10001 and Grafana as UID 472. Will cause permission denied errors at runtime. Fix `init-host.sh` to `chown` these directories to the correct UIDs.
- Gitea SSH port not exposed — No SSH port mapped in docker-compose.yml. Decide in Story 1.4 whether to expose port 2222:22 for Git-over-SSH or go HTTPS-only (with `DISABLE_SSH=true`). Full Gitea env var context needed to configure correctly.
