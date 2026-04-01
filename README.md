# homelab

Self-hosted home automation and AI-powered services on a single Fedora server.

## Prerequisites

- Fedora (tested on Fedora 43+)
- Docker and Docker Compose v5
- 32GB RAM recommended

## Quick Start

```bash
# Initialize host directories and environment
scripts/init-host.sh

# Edit .env with your secrets
nano .env

# Start all services
docker compose up -d
```
