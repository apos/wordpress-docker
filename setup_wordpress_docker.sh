#!/bin/bash
set -e

# Konfigurationsdatei einbinden
CONFIG_FILE="$HOME/config/wordpress-docker-qs-knowledgebase.sh"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Konfigurationsdatei nicht gefunden: $CONFIG_FILE"
  exit 1
fi
source "$CONFIG_FILE"

cd "$PROJECT_DIR"

# nginx.conf erzeugen
echo "📄 Erzeuge nginx.conf..."
cat <<NGINX > nginx.conf
server {
    listen 80;
    server_name ${DOMAIN_IP};

    root /var/www/html;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        include fastcgi_params;
        fastcgi_pass wp_app:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    location ~ /\.ht {
        deny all;
    }
}
NGINX

# Leere wp-config.php erzeugen (um Autogenerierung zu blockieren)
echo "<?php // placeholder to block auto-generation ?>" > temp-wp-config.php

echo "🔄 Starte alle Docker-Container..."
docker compose up -d

echo "🧹 Entferne Platzhalter-Datei lokal + im Container (vor WP-CLI)..."
docker compose exec -T wordpress rm -f /var/www/html/wp-config.php || true
rm -f temp-wp-config.php

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

echo "📄 Generiere neue wp-config.php via WP-CLI..."
docker compose exec -T wpcli wp core config \
  --dbname="${DB_NAME}" \
  --dbuser="${DB_USER}" \
  --dbpass="${DB_PASS}" \
  --dbhost="db:3306" \
  --skip-check

# WordPress installieren (falls noch nicht)
if docker compose exec -T wpcli wp core is-installed; then
  echo "ℹ️ WordPress ist bereits installiert."
else
  echo "⚙️ WordPress wird jetzt installiert..."
  docker compose exec -T wpcli env HTTP_HOST=localhost wp core install \
    --url="http://${DOMAIN_IP}:${PORT}" \
    --title="${WP_TITLE}" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${WP_ADMIN_PASS}" \
    --admin_email="${WP_ADMIN_EMAIL}"
  echo "✅ WordPress Installation abgeschlossen!"
fi

# Erfolgsmeldung
echo ""
echo "🎉 WordPress wurde erfolgreich eingerichtet!"
echo "🌍 ➜ Jetzt im Browser öffnen: http://${DOMAIN_IP}:${PORT}/"
echo "🔐 Admin: ${WP_ADMIN_USER} / ${WP_ADMIN_PASS}"