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

echo "🔄 Starte alle Docker-Container..."
docker compose up -d

# Platzhalter erzeugen (als www-data)
echo "📄 Erzeuge Platzhalter wp-config.php direkt im Container (als www-data)..."
docker compose exec -T wordpress sh -c 'echo "<?php // placeholder ?>" | sudo -u www-data tee /var/www/html/wp-config.php > /dev/null'

# Datei beschreibbar machen für WP-CLI (läuft als root)
echo "🔧 Setze Schreibrechte auf wp-config.php für WP-CLI..."
docker compose exec -T wordpress chmod 666 /var/www/html/wp-config.php || true

# Datei entfernen vor WP-CLI
echo "🧹 Entferne Platzhalter-Datei im Container (vor WP-CLI)..."
docker compose exec -T wordpress rm -f /var/www/html/wp-config.php || true

# Datenbankverbindung abwarten
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

# Schreibrechte auf wp-config.php erweitern (falls vorhanden)
echo "🔧 Setze Schreibrechte auf wp-config.php (für WP-CLI)..."
docker compose exec -T wordpress chmod 666 /var/www/html/wp-config.php || true

echo "📄 Generiere neue wp-config.php via WP-CLI..."
docker compose exec -T wpcli wp core config \
  --dbname="${DB_NAME}" \
  --dbuser="${DB_USER}" \
  --dbpass="${DB_PASS}" \
  --dbhost="db:3306" \
  --skip-check

# Rechte wieder einschränken
echo "🔐 Setze sichere Rechte für wp-config.php..."
docker compose exec -T wordpress chmod 640 /var/www/html/wp-config.php || true

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