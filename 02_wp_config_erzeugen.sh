#!/bin/bash
set -e

# Konfiguration laden
CONFIG_FILE="$HOME/config/wordpress-docker-qs-knowledgebase.sh"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Konfigurationsdatei nicht gefunden: $CONFIG_FILE"
  exit 1
fi
source "$CONFIG_FILE"

echo "⏳ Warte auf Datenbankverbindung..."
for i in {1..30}; do
  if docker compose exec -T db mysql -u"${DB_USER}" -p"${DB_PASS}" -e "SELECT 1;" "${DB_NAME}" &>/dev/null; then
    echo "✅ Datenbankverbindung steht!"
    break
  else
    echo "  ⏳ Datenbank noch nicht bereit... ($i/30)"
    sleep 2
  fi
done

echo "🧹 Entferne alte wp-config.php im wpcli-Container (falls vorhanden)..."
docker compose exec -T wpcli rm -f /var/www/html/wp-config.php || true

echo "🔧 Setze Schreibrechte auf /var/www/html für wp-config.php..."
docker compose exec -T wpcli chmod 777 /var/www/html || true

echo "🔧 Erzeuge neue wp-config.php via WP-CLI..."
docker compose exec -T wpcli wp config create --allow-root \
  --dbname="${DB_NAME}" \
  --dbuser="${DB_USER}" \
  --dbpass="${DB_PASS}" \
  --dbhost="db:3306" \
  --skip-check

echo "🔐 Setze sichere Rechte für wp-config.php..."
docker compose exec -T wpcli chmod 640 /var/www/html/wp-config.php || true

echo "✅ wp-config.php wurde erfolgreich erzeugt."