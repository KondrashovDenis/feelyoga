#!/usr/bin/env bash
# 04-import-to-vps.sh — импортировать БД + upload с debianOCR в свежий FeelYoga на VPS.
#
# Предусловие: 02-install-feelyoga.sh выполнен (Orbita запущен), 03-export-from-dev.sh
# выполнен на debianOCR, директория экспорта скопирована на VPS через scp.
#
# Использование:
#   bash 04-import-to-vps.sh /tmp/feelyoga-migration-2026-05-15

set -euo pipefail

MIGRATION_DIR="${1:-}"
INSTALL_DIR="${INSTALL_DIR:-/opt/feelyoga}"

if [[ -z "$MIGRATION_DIR" || ! -d "$MIGRATION_DIR" ]]; then
    echo "Использование: bash 04-import-to-vps.sh /path/to/migration-dir"
    echo ""
    echo "Папка должна содержать:"
    echo "  db.sql"
    echo "  upload.tar.gz"
    exit 1
fi

cd "$INSTALL_DIR"

# --- Проверка что контейнеры подняты ---
if ! docker compose ps mariadb 2>/dev/null | grep -q Up; then
    echo "✗ MariaDB не запущен. Сначала: cd $INSTALL_DIR && docker compose up -d"
    exit 1
fi

DB_USER=$(grep '^DB_USERNAME=' .env | cut -d= -f2)
DB_PASS=$(grep '^DB_PASSWORD=' .env | cut -d= -f2)
DB_NAME=$(grep '^DB_DATABASE=' .env | cut -d= -f2)

# --- Импорт БД ---
echo "==> импортирую БД ($(du -h "$MIGRATION_DIR/db.sql" | cut -f1))"
cat "$MIGRATION_DIR/db.sql" | docker compose exec -T mariadb \
    mariadb -u "$DB_USER" -p"$DB_PASS" "$DB_NAME"
echo "  ✓ БД импортирована"

# --- Импорт upload ---
echo "==> распаковываю upload ($(du -h "$MIGRATION_DIR/upload.tar.gz" | cut -f1))"
# Сохраняем текущий upload как backup
if [[ -d upload && -n "$(ls -A upload 2>/dev/null)" ]]; then
    mv upload "upload.backup-$(date +%F-%H%M%S)"
fi
tar -xzf "$MIGRATION_DIR/upload.tar.gz" -C "$INSTALL_DIR/"
docker compose exec -T php-fpm chown -R www-data:www-data /vesp/upload
echo "  ✓ upload распакован"

# --- Restart сервисов чтобы перечитали кеши ---
echo "==> рестарт node + php-fpm"
docker compose restart node php-fpm

echo ""
echo "================================================="
echo "✓ Импорт завершён"
echo ""
echo "Проверь:"
echo "  - админка должна показывать все настройки/файлы/топики из dev"
echo "  - admin/admin пароль ТОТ ЖЕ что был на debianOCR"
echo "  - картинки/видео должны открываться"
echo "================================================="
