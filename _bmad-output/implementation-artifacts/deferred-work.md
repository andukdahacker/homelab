# Deferred Work

## Deferred from: code review of 1-1-project-repository-host-initialization (2026-04-01)

- Default secrets (`changeme` for Grafana, `changeme-generate-a-random-key` for n8n) are copied verbatim into `.env` with no runtime validation — user must manually edit before `docker compose up`
- CADDY_DOMAIN defaults to `homelab.local` with no TLS guidance — Caddy/TLS configuration is Story 1.2/1.3
- `docker plugin install` uses `--grant-all-permissions` which blindly grants all plugin-requested permissions — standard for Loki driver install but worth revisiting if plugin scope changes
- `docker-compose.yml` missing `env_file: .env` directive — deferred to Story 1.2 when actual services are added (env_file is a per-service key)
