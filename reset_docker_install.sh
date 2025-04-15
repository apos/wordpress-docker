#!/bin/bash
set -e

echo "🧹 Setze WordPress-Docker-Installation zurück..."
docker compose down --volumes
docker volume prune -f
sudo rm -rf ./wp_data
echo "✅ Zurückgesetzt. Starte nun 01_container_bauen.sh erneut."