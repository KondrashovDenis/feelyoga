#!/usr/bin/env bash
# 03-export-from-dev.sh — собрать дамп БД + upload + .env с debianOCR
# для переноса на VPS. Запускать на debianOCR.
#
# Делает БД-дамп ONLINE (mariadb-dump в работающем контейнере) — downtime НЕ нужен.
# upload запаковывается как есть.
#
# Использование:
#   bash 03-export-from-dev.sh
#
# Результат:
#   /tmp/feelyoga-migration-YYYY-MM-DD/
#     ├── db.sql              — дамп БД
#     ├── upload.tar.gz       — все файлы пользователей (видео, картинки)
#     └── env.txt             — оригинальный .env (содержит секреты — НЕ публиковать!)

set -euo pipefail

ORBITA_DIR="${ORBITA_DIR:-$HOME/projects/feelyoga}"
OUT="/tmp/feelyoga-migration-$(date +%F)"
mkdir -p "$OUT"

cd "$ORBITA_DIR"

# --- БД-дамп (онлайн, без downtime) ---
echo "==> mariadb-dump"
DB_USER=$(grep '^DB_USERNAME=' .env | cut -d= -f2)
DB_PASS=$(grep '^DB_PASSWORD=' .env | cut -d= -f2)
DB_NAME=$(grep '^DB_DATABASE=' .env | cut -d= -f2)

docker compose exec -T mariadb \
    mariadb-dump -u "$DB_USER" -p"$DB_PASS" \
    --single-transaction --quick --routines --triggers \
    "$DB_NAME" > "$OUT/db.sql"

echo "  размер: $(du -h "$OUT/db.sql" | cut -f1)"

# --- Upload файлы ---
echo "==> tar upload"
tar -czf "$OUT/upload.tar.gz" upload/
echo "  размер: $(du -h "$OUT/upload.tar.gz" | cut -f1)"

# --- .env (с секретами!) ---
cp .env "$OUT/env.txt"
chmod 600 "$OUT/env.txt"
echo "  .env скопирован (содержит секреты — chmod 600)"

# --- Итог ---
echo ""
echo "================================================="
echo "✓ Экспорт готов: $OUT"
ls -lh "$OUT"
echo ""
echo "Передать на VPS:"
echo "  scp -r $OUT root@<VPS_IP>:/tmp/"
echo ""
echo "На VPS: bash 04-import-to-vps.sh /tmp/feelyoga-migration-$(date +%F)"
echo "================================================="
