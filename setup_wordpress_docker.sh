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
cat <<EOF > nginx.conf
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
EOF

echo "🔄 Starte alle Docker-Container..."
docker compose up -d

# DB-Verbindung abwarten
echo "⏳ Warte auf Datenbankverbindung..."
for i in {1..30}; do
  if docker compose exec -T db mysql -u"${DB_USER}" -p"${DB_PASS}" -e "SELECT 1;" "${DB_NAME}" &>/dev/null; then
    echo "✅ Datenbankverbindung steht!"
    break
  else
    echo "  ⏳ Datenbank noch nicht bereit... ($i/30)"
    sleep 2
  fi
  [[ "$i" == 30 ]] && { echo "❌ DB nicht erreichbar"; exit 1; }
done

echo "🧹 Entferne evtl. vorhandene wp-config.php (wordpress-Container)..."
docker compose exec -T wordpress sh -c "rm -f /var/www/html/wp-config.php || true"
docker compose exec -T wpcli     sh -c "rm -f /var/www/html/wp-config.php || true"

echo "🔧 Setze Schreibrechte auf /var/www/html (wordpress)..."
docker compose exec -T wordpress chmod u+w /var/www/html

echo "📄 Lege temporäre wp-config.php im Container an..."
echo "<?php // placeholder ?>" > "$PROJECT_DIR/temp-wp-config.php"
docker cp "$PROJECT_DIR/temp-wp-config.php" wp_app:/var/www/html/wp-config.php
rm "$PROJECT_DIR/temp-wp-config.php"

echo "🔧 Setze Besitzer + Schreibrechte auf wp-config.php (im Container)..."
docker compose exec -T wordpress chown www-data:www-data /var/www/html/wp-config.php
docker compose exec -T wordpress chmod u+w /var/www/html/wp-config.php

echo "📄 Generiere neue wp-config.php via WP-CLI..."
docker compose exec -T wpcli wp core config \
  --dbname="${DB_NAME}" \
  --dbuser="${DB_USER}" \
  --dbpass="${DB_PASS}" \
  --dbhost="db:3306" \
  --skip-check

# Installation prüfen
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

echo ""
echo "🎉 WordPress wurde erfolgreich eingerichtet!"
echo "🌍 ➜ Jetzt im Browser öffnen: http://${DOMAIN_IP}:${PORT}/"
echo "🔐 Admin-Zugang:"
echo "   Benutzer: ${WP_ADMIN_USER}"
echo "   Passwort: ${WP_ADMIN_PASS}"