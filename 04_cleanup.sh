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

# 🧹 Entferne phpinfo-Datei, falls vorhanden
echo "🧹 Entferne phpinfo-Testdatei (falls vorhanden)..."
docker compose exec -T wordpress rm -f /var/www/html/phpinfo.php || true

# 🔐 Setze Besitzer und Rechte auf wp-config.php im Anwendungscontainer
echo "🔐 Setze Besitzer von wp-config.php auf www-data..."
docker exec -it wp_app chown www-data:www-data /var/www/html/wp-config.php

echo "🔐 Setze Dateirechte von wp-config.php auf 640..."
docker exec -it wp_app chmod 640 /var/www/html/wp-config.php

echo "✅ Cleanup abgeschlossen."