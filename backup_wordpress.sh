#!/bin/bash
set -e

VERSION="v1.0"
DATE="$(date +%F)"
DEFAULT_DIR="$HOME/Downloads/backup_wordpress_${DATE}_$VERSION"
BACKUP_DIR="${1:-$DEFAULT_DIR}"

echo "📦 Erstelle WordPress-Backup unter: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# 1. wp-content sichern
echo "📁 Sichere wp-content..."
docker cp wp_app:/var/www/html/wp-content "$BACKUP_DIR/"

# 2. wp-config.php sichern
echo "📄 Sichere wp-config.php..."
docker cp wp_app:/var/www/html/wp-config.php "$BACKUP_DIR/"

# 3. Datenbank-Dump
echo "🗄️ Erstelle Datenbank-Dump (wp_db)..."
docker exec wp_db sh -c 'exec mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE"' > "$BACKUP_DIR/db.sql"

echo "✅ Backup abgeschlossen: $BACKUP_DIR"