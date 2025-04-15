#!/bin/bash
set -e

BACKUP_DIR="${1:-}"
if [[ -z "$BACKUP_DIR" ]]; then
  echo "❌ Bitte gib das Backup-Verzeichnis an:"
  echo "   ./restore_wordpress.sh /pfad/zum/backup_wordpress_YYYY-MM-DD_vX.Y.Z"
  exit 1
fi

if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "❌ Verzeichnis existiert nicht: $BACKUP_DIR"
  exit 1
fi

echo "♻️ Stelle WordPress-Backup aus '$BACKUP_DIR' wieder her..."

# 1. wp-content zurückspielen
if [[ -d "$BACKUP_DIR/wp-content" ]]; then
  echo "📁 Stelle wp-content wieder her..."
  docker cp "$BACKUP_DIR/wp-content" wp_app:/var/www/html/
else
  echo "⚠️ wp-content nicht gefunden – wird übersprungen."
fi

# 2. wp-config.php zurückspielen
if [[ -f "$BACKUP_DIR/wp-config.php" ]]; then
  echo "📄 Stelle wp-config.php wieder her..."
  docker cp "$BACKUP_DIR/wp-config.php" wp_app:/var/www/html/wp-config.php
else
  echo "⚠️ wp-config.php nicht gefunden – wird übersprungen."
fi

# 3. Datenbank zurückspielen
if [[ -f "$BACKUP_DIR/db.sql" ]]; then
  echo "🗄️ Spiele Datenbank-Dump ein..."
  DB_NAME=$(docker exec -it wp_db printenv MYSQL_DATABASE | tr -d '\r')
  echo "ℹ️ Verwende Datenbank: $DB_NAME"
  docker exec -i wp_db sh -c "exec mysql -uroot -p\"\$MYSQL_ROOT_PASSWORD\" \"$DB_NAME\"" < "$BACKUP_DIR/db.sql"
else
  echo "⚠️ db.sql nicht gefunden – wird übersprungen."
fi

# 🔐 Rechte setzen für wp-config.php (UID 82 = www-data im wp_cli-Container)
echo "🔐 Setze Besitzer von wp-config.php auf UID 82 (www-data)..."
docker exec -it wp_app chown 82:82 /var/www/html/wp-config.php
echo "🔐 Setze Dateirechte auf 640..."
docker exec -it wp_app chmod 640 /var/www/html/wp-config.php

# 🔁 WP-CLI-Container neu starten, damit neue config erkannt wird
echo "🔄 Starte wp_cli-Container neu..."
docker compose restart wpcli

echo "✅ Wiederherstellung abgeschlossen."