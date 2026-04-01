#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CURRENT_USER="${USER:-$(id -un)}"

echo "=== Homelab Host Initialization ==="

# Check Docker is installed
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed."
    echo "Install Docker first: https://docs.docker.com/engine/install/fedora/"
    exit 1
fi

# Check Docker daemon is running
if ! docker info &> /dev/null; then
    echo "ERROR: Docker daemon is not running or current user lacks permissions."
    echo "Try: sudo systemctl start docker"
    exit 1
fi

# Create bind mount directories
SERVICES=(ollama grafana loki qdrant gitea n8n caddy)
echo "Creating bind mount directories under /data/homelab/..."
for svc in "${SERVICES[@]}"; do
    sudo mkdir -p "/data/homelab/${svc}"
done
sudo chmod 755 /data/homelab/ /data/homelab/*/
sudo chown -R "$CURRENT_USER:$CURRENT_USER" /data/homelab/

echo "Bind mount directories created."

# Copy .env.example to .env if .env does not exist
if [ ! -f "$REPO_ROOT/.env" ]; then
    if [ ! -f "$REPO_ROOT/.env.example" ]; then
        echo "ERROR: .env.example not found at $REPO_ROOT/.env.example"
        exit 1
    fi
    install -m 600 "$REPO_ROOT/.env.example" "$REPO_ROOT/.env"
    echo "Created .env from .env.example (mode 600) — edit it with your secrets."
else
    echo ".env already exists — skipping copy."
fi

# Install Loki Docker log driver plugin if not already installed
if docker plugin ls --format '{{.Name}}' 2>/dev/null | grep -q 'grafana/loki-docker-driver'; then
    echo "Loki Docker log driver plugin already installed."
else
    echo "Installing Loki Docker log driver plugin..."
    docker plugin install grafana/loki-docker-driver:3.3.3 --alias loki --grant-all-permissions
    echo "Loki Docker log driver plugin installed."
fi

echo ""
echo "=== Initialization complete ==="
echo "Next steps:"
echo "  1. Edit .env with your secrets"
echo "  2. Run: docker compose up -d"
