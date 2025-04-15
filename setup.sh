#!/bin/bash
set -e

echo "🚀 Starte WordPress-Docker-Setup..."

if [[ "$1" == "--clean" ]]; then
  echo "🧹 Vollständiges Zurücksetzen vor Installation..."
  ./reset_docker_install.sh
else
  # Optionales Cleanup: wp_cli Containerreste entfernen
  if docker ps -a --format '{{.Names}}' | grep -q '^wp_cli$'; then
    echo "🧹 Entferne alten wp_cli-Container..."
    docker rm -f wp_cli
  fi
fi

./01_container_bauen.sh
./02_wp_config_erzeugen.sh
./03_Wordpress_installieren.sh
./04_cleanup.sh

echo "✅ WordPress-Docker-Installation abgeschlossen!"
echo "🌐 Seite im Browser öffnen: http://localhost:8088"