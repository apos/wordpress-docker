#!/bin/bash
set -e

# Konfigurationsdatei einbinden
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

echo "🔧 Setze Schreibrechte auf /var/www/html (wordpress)..."
docker compose exec -T wordpress chmod u+w /var/www/html

echo "🧹 Entferne evtl. vorhandene wp-config.php im Container..."
docker compose exec -T wordpress rm -f /var/www/html/wp-config.php || true

echo "📄 Starte WordPress-Installation..."
docker compose exec -T wpcli env HTTP_HOST=localhost wp core install --allow-root \
  --url="http://${DOMAIN_IP}:${PORT}" \
  --title="${WP_TITLE}" \
  --admin_user="${WP_ADMIN_USER}" \
  --admin_password="${WP_ADMIN_PASS}" \
  --admin_email="${WP_ADMIN_EMAIL}" \
  --skip-email

echo "🔐 Setze Rechte auf wp-config.php..."
docker compose exec -T wordpress chmod 640 /var/www/html/wp-config.php || true

echo "✅ WordPress wurde erfolgreich installiert!"