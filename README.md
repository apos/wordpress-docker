## 🚀 WordPress-Docker: Setup & Struktur

Dieses Projekt stellt eine minimalistische, nachvollziehbare Umgebung bereit, um WordPress mit Docker Compose lokal zu betreiben. Es umfasst:

- PHP-FPM (`wordpress:php8.2-fpm`)
- NGINX als Reverse-Proxy
- MariaDB als Datenbank
- WP-CLI als eigenständiger Container

### 📂 Struktur der Setup-Skripte

| Skript                   | Funktion                                                   |
|--------------------------|------------------------------------------------------------|
| `setup.sh`               | Führt das vollständige Setup durch (Container + WP-Install) |
| `reset_docker_install.sh`| Entfernt Container, Volumes, Netzwerke (Hard Reset)         |
| `01_container_bauen.sh`  | Startet die Container und erzeugt die `nginx.conf`          |
| `02_wp_config_erzeugen.sh`| Erstellt `wp-config.php` via WP-CLI                        |
| `03_Wordpress_installieren.sh` | Installiert WordPress via WP-CLI (Admin-Zugang)     |
| `04_cleanup.sh`          | Entfernt phpinfo, setzt sichere Rechte, wechselt WP-CLI-Nutzer zurück zu `www-data` |

### 🧪 Setup starten

```bash
./setup.sh             # Normales Setup mit bestehenden Daten
./setup.sh --clean     # Volles Zurücksetzen + frische Installation
```

Browserzugriff: [http://localhost:8088](http://localhost:8088)

### 🛠️ Debug-Hinweise

- Fehlerhafte Seite (weiß): prüfen via  
  `docker logs wp_app | tail -n 50`
- Datenbank noch nicht bereit? Skripte warten automatisch auf Verfügbarkeit
- WP-CLI läuft nach dem Setup **nicht mehr als root**, sondern als `www-data` (UID 82)

### 📦 Nächste Schritte

Backup- & Restore-Skripte folgen zur Sicherung/Übernahme der WordPress-Installation.
