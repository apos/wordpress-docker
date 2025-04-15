#!/bin/bash
set -e

# Konfigurationsdatei einbinden
CONFIG_FILE="$HOME/config/wordpress-docker-qs-knowledgebase.sh"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Konfigurationsdatei nicht gefunden: $CONFIG_FILE"
  exit 1
fi
source "$CONFIG_FILE"

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

echo "📄 Verhindere automatische Generierung von wp-config.php..."
echo "<?php // placeholder ?>" > temp-wp-config.php

echo "🔄 Starte alle Docker-Container..."
docker compose up -d

echo "🧹 Entferne Platzhalter-Datei lokal und im Container..."
rm -f temp-wp-config.php
docker compose exec -T wordpress rm -f /var/www/html/wp-config.php || true

echo "✅ Container laufen. Jetzt kannst du '02_Wordpress_installieren.sh' ausführen."