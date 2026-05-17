#!/usr/bin/env bash
# 02-install-feelyoga.sh — установка FeelYoga на подготовленный VPS.
#
# Предусловие: 01-install-vps.sh выполнен (Docker + Caddy + swap + UFW есть).
#
# Два режима:
#   --mode prebuilt (по умолчанию для слабых VPS) — pre-built .output скачивается
#                    с PREBUILT_URL, на VPS НЕТ npm i / nuxt build. Требуется
#                    ~3GB свободного диска. Идеально для 1-2 vCPU / 1-2 GB RAM.
#
#   --mode build — на VPS выполнится npm i + nuxt build (тяжело).
#                  Нужен 2+ vCPU, 4+ GB RAM, 20+ GB диска. Подходит для Timeweb
#                  и других нормальных VPS, либо для случая когда нет dev-машины
#                  где можно собрать.
#
# Использование:
#   bash 02-install-feelyoga.sh                    # prebuilt по умолчанию
#   bash 02-install-feelyoga.sh --mode build
#   PREBUILT_URL=https://my.cdn/output.tar.gz bash 02-install-feelyoga.sh

set -euo pipefail

# --- Аргументы и env ---
MODE="prebuilt"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode) MODE="$2"; shift 2 ;;
        --mode=*) MODE="${1#*=}"; shift ;;
        *) echo "Unknown arg: $1"; exit 1 ;;
    esac
done

INSTALL_DIR="${INSTALL_DIR:-/opt/feelyoga}"
CONFIG_REPO_URL="${CONFIG_REPO_URL:-https://github.com/KondrashovDenis/feelyoga.git}"
ORBITA_REPO_URL="${ORBITA_REPO_URL:-https://github.com/bezumkin/orbita.git}"
PREBUILT_URL="${PREBUILT_URL:-https://vaibkod.online/feelyoga-output.tar.gz}"
TMP_CONFIG="/tmp/feelyoga-config-$$"

if [[ "$MODE" != "prebuilt" && "$MODE" != "build" ]]; then
    echo "✗ Неизвестный mode: $MODE (нужен 'prebuilt' или 'build')"
    exit 1
fi

echo "==> mode: $MODE"

# --- Промпт пользователя ---
read -rp "Домен (например vps.vaibkod.online): " DOMAIN
read -rp "Email для Let's Encrypt [denciaopin@gmail.com]: " EMAIL
EMAIL="${EMAIL:-denciaopin@gmail.com}"

if [[ -z "$DOMAIN" ]]; then
    echo "✗ Домен обязателен"
    exit 1
fi

# --- DNS проверка ---
echo "==> проверяю DNS"
RESOLVED=$(getent ahostsv4 "$DOMAIN" 2>/dev/null | head -1 | awk '{print $1}' || true)
IP=$(curl -s ifconfig.me || echo "?")
if [[ -z "${RESOLVED:-}" ]]; then
    echo "⚠ Не смог зарезолвить $DOMAIN. Проверь A-запись."
elif [[ "$RESOLVED" != "$IP" ]]; then
    echo "⚠ $DOMAIN → $RESOLVED, но мой IP = $IP. Caddy не получит сертификат."
else
    echo "✓ DNS ок: $DOMAIN → $IP"
fi

# --- 1. Клонировать Orbita ---
if [[ ! -d "$INSTALL_DIR" ]]; then
    echo "==> git clone Orbita в $INSTALL_DIR"
    git clone "$ORBITA_REPO_URL" "$INSTALL_DIR"
else
    echo "==> $INSTALL_DIR уже существует, пропускаю clone"
fi

# --- 2. Клонировать наш конфиг-репо ---
echo "==> git clone feelyoga config в $TMP_CONFIG"
git clone --depth 1 "$CONFIG_REPO_URL" "$TMP_CONFIG"
trap "rm -rf $TMP_CONFIG" EXIT

# --- 3. Наложить overlay (Vue компоненты + SCSS) ---
echo "==> накладываю customizations"
cp -r "$TMP_CONFIG/deploy/customizations/frontend/." "$INSTALL_DIR/frontend/"
mkdir -p "$INSTALL_DIR/.local/vesp"
cp "$TMP_CONFIG/deploy/.local/vesp/get-api.js" "$INSTALL_DIR/.local/vesp/get-api.js"

# --- 4. docker-compose.override.yml — разный для двух режимов ---
if [[ "$MODE" == "prebuilt" ]]; then
    echo "==> mode=prebuilt → скачиваю .output с $PREBUILT_URL"
    curl -fsSL "$PREBUILT_URL" -o /tmp/feelyoga-output.tar.gz
    tar -xzf /tmp/feelyoga-output.tar.gz -C "$INSTALL_DIR/frontend/"
    ls "$INSTALL_DIR/frontend/.output/server/index.mjs" > /dev/null
    echo "    ✓ .output/server/index.mjs готов"

    cat > "$INSTALL_DIR/docker-compose.override.yml" <<'EOF'
services:
  node:
    # Pre-built deployment: .output скачан с dev-сборки, билд на VPS пропущен.
    # Подходит для слабых VPS (1-2 vCPU, 1-2 GB RAM, 10 GB диск).
    command: sh -c 'node ./.output/server/index.mjs'
    environment:
      - SERVER_SITE_URL=http://nginx/
    volumes:
      - ./.local/vesp/get-api.js:/vesp/frontend/node_modules/@vesp/frontend/dist/runtime/utils/get-api.js
EOF
else
    echo "==> mode=build → используется обычный override (npm i + nuxt build на старте node)"
    cp "$TMP_CONFIG/deploy/docker-compose.override.standalone.yml" "$INSTALL_DIR/docker-compose.override.yml"
fi

# --- 5. .env с секретами ---
if [[ ! -f "$INSTALL_DIR/.env" ]]; then
    echo "==> генерирую .env"
    DB_PASS=$(openssl rand -base64 24 | tr -d '/+=' | head -c 32)
    JWT=$(openssl rand -base64 48 | tr -d '/+=' | head -c 64)
    SOCK=$(openssl rand -base64 32 | tr -d '/+=' | head -c 40)
    sed -e "s|<DOMAIN>|$DOMAIN|g" \
        -e "s|<DB_PASSWORD>|$DB_PASS|g" \
        -e "s|<JWT_SECRET>|$JWT|g" \
        -e "s|<SOCKET_SECRET>|$SOCK|g" \
        "$TMP_CONFIG/deploy/.env.standalone.template" > "$INSTALL_DIR/.env"
    echo "  DB_PASSWORD сгенерирован и сохранён в $INSTALL_DIR/.env"
else
    echo "==> .env уже есть, не трогаю"
fi

# --- 6. Запуск ---
cd "$INSTALL_DIR"
echo "==> docker compose pull"
docker compose pull
echo "==> docker compose up -d"
docker compose up -d

# --- 7. Фикс прав ---
echo "==> жду php-fpm"
sleep 5
docker compose exec -T php-fpm chown -R www-data:www-data /vesp/upload /vesp/tmp /vesp/log

# --- 8. Caddyfile ---
echo "==> настраиваю Caddyfile"
NGINX_PORT=$(grep '^NGINX_PORT=' "$INSTALL_DIR/.env" | cut -d= -f2)
sed -e "s|<DOMAIN>|$DOMAIN|g" \
    -e "s|<EMAIL>|$EMAIL|g" \
    -e "s|localhost:8080|localhost:$NGINX_PORT|g" \
    "$TMP_CONFIG/deploy/caddy/Caddyfile.standalone" > /etc/caddy/Caddyfile

caddy validate --config /etc/caddy/Caddyfile
systemctl reload caddy

echo ""
echo "================================================="
echo "✓ FeelYoga установлен (mode=$MODE)"
echo "  Установка:  $INSTALL_DIR"
echo "  Домен:      https://$DOMAIN"
echo "  Админка:    https://$DOMAIN/admin  (admin/admin → СМЕНИТЬ)"
echo ""
if [[ "$MODE" == "build" ]]; then
    echo "  ⏳ Node ещё билдит Nuxt (5-15 минут). Следи:"
    echo "     docker compose -f $INSTALL_DIR/docker-compose.yml logs node --tail 20"
else
    echo "  ✓ Pre-built deploy: node стартанул мгновенно, билд не нужен"
fi
echo ""
echo "  Логи Nuxt:  docker compose -f $INSTALL_DIR/docker-compose.yml logs -f node"
echo "  Логи Caddy: journalctl -u caddy -f"
echo ""
echo "Импорт БД + upload с dev: bash <(curl -fsSL https://vaibkod.online/import-data-vps.sh)"
echo "================================================="
