#!/bin/bash
set -e

echo "🔧 Setze Benutzer des wpcli-Containers zurück auf 'www-data' (UID 82)..."

# Aktuelle Konfiguration sichern
docker compose stop wpcli

# Container mit neuer UID starten (als www-data)
docker compose rm -f wpcli
docker compose run -d \
  --name wp_cli \
  --user "82" \
  --entrypoint "tail -f /dev/null" \
  wordpress:cli

echo "✅ wpcli läuft jetzt wieder als www-data (UID 82)."