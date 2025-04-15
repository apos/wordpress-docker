#!/bin/bash

echo "🧹 Setze WordPress-Docker-Installation zurück..."
docker compose down --volumes
docker volume prune -f
sudo rm -rf ./wp_data
echo "✅ Zurückgesetzt. Starte nun setup_wordpress_docker.sh erneut."