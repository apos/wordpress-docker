## 🚀 WordPress-Docker: Setup & Structure

This project provides a minimalist, structured Docker Compose setup to run WordPress locally. It includes:

- PHP-FPM (`wordpress:php8.2-fpm`)
- NGINX as reverse proxy
- MariaDB as the database
- WP-CLI as a standalone container

### 📂 Script Overview

| Script                   | Purpose                                                    |
|--------------------------|------------------------------------------------------------|
| `setup.sh`               | Runs the full setup (containers + WordPress installation)  |
| `reset_docker_install.sh`| Destroys all containers, volumes, networks (full reset)     |
| `01_container_bauen.sh`  | Starts containers and generates `nginx.conf`               |
| `02_wp_config_erzeugen.sh`| Creates `wp-config.php` via WP-CLI                        |
| `03_Wordpress_installieren.sh` | Installs WordPress via WP-CLI (admin user)          |
| `04_cleanup.sh`          | Removes phpinfo, sets secure permissions, resets WP-CLI to `www-data` UID 82 |

### 🧪 Run Setup

```bash
./setup.sh             # Standard setup with existing data
./setup.sh --clean     # Full reset and fresh installation
```

Access WordPress in your browser: [http://localhost:8088](http://localhost:8088)

### 🛠️ Debug Tips

- Blank page? Check:
  `docker logs wp_app | tail -n 50`
- Database not ready yet? Scripts will wait automatically
- WP-CLI is **no longer running as root**, but as `www-data` (UID 82)

### 📦 Coming up

Backup & restore scripts will follow to preserve or migrate your WordPress installation.
