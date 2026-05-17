#!/usr/bin/env bash
# 02-install-feelyoga.sh — установка FeelYoga на подготовленный VPS.
#
# Предусловие: 01-install-vps.sh выполнен (Docker + Caddy + swap + UFW есть).
#
# Что делает:
#   1. Клонирует upstream Orbita в /opt/feelyoga
#   2. Клонирует наш конфиг-репо feelyoga (для customizations) во временную папку
#   3. Накладывает overlay (deploy/customizations/frontend → /opt/feelyoga/frontend)
#   4. Кладёт docker-compose.override.standalone.yml как override.yml
#   5. Запрашивает у пользователя домен и email
#   6. Генерирует .env с свежими секретами
#   7. docker compose pull + up -d
#   8. chown www-data на upload/tmp/log (грабля 2026-05-15)
#   9. Настраивает /etc/caddy/Caddyfile и reload caddy
#
# Использование:
#   bash 02-install-feelyoga.sh

set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-/opt/feelyoga}"
CONFIG_REPO_URL="${CONFIG_REPO_URL:-https://github.com/KondrashovDenis/feelyoga.git}"
ORBITA_REPO_URL="${ORBITA_REPO_URL:-https://github.com/bezumkin/orbita.git}"
TMP_CONFIG="/tmp/feelyoga-config-$$"

# --- Промпт пользователя ---
read -rp "Домен (например vps.vaibkod.online): " DOMAIN
read -rp "Email для Let's Encrypt [denciaopin@gmail.com]: " EMAIL
EMAIL="${EMAIL:-denciaopin@gmail.com}"

if [[ -z "$DOMAIN" ]]; then
    echo "✗ Домен обязателен"
    exit 1
fi

# --- DNS проверка (необязательная) ---
echo "==> проверяю DNS"
RESOLVED=$(dig +short A "$DOMAIN" 2>/dev/null | head -1 || echo "")
IP=$(curl -s ifconfig.me || echo "?")
if [[ -z "$RESOLVED" ]]; then
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

# --- 2. Клонировать наш конфиг-репо во временную папку ---
echo "==> git clone feelyoga config в $TMP_CONFIG"
git clone --depth 1 "$CONFIG_REPO_URL" "$TMP_CONFIG"
trap "rm -rf $TMP_CONFIG" EXIT

# --- 3. Наложить overlay (Vue компоненты + SCSS) ---
echo "==> накладываю customizations"
cp -r "$TMP_CONFIG/deploy/customizations/frontend/." "$INSTALL_DIR/frontend/"
mkdir -p "$INSTALL_DIR/.local/vesp"
cp "$TMP_CONFIG/deploy/.local/vesp/get-api.js" "$INSTALL_DIR/.local/vesp/get-api.js"

# --- 4. docker-compose.override.yml (standalone-вариант) ---
cp "$TMP_CONFIG/deploy/docker-compose.override.standalone.yml" "$INSTALL_DIR/docker-compose.override.yml"

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
echo "==> docker compose up -d (5-10 минут на первый билд Nuxt)"
docker compose up -d

# --- 7. Фикс прав (грабля 2026-05-15) ---
echo "==> жду пока php-fpm стартанёт"
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
echo "✓ FeelYoga установлен"
echo "  Установка:  $INSTALL_DIR"
echo "  Домен:      https://$DOMAIN"
echo "  Админка:    https://$DOMAIN/admin  (admin/admin → СМЕНИТЬ)"
echo ""
echo "  Логи Nuxt:  docker compose -f $INSTALL_DIR/docker-compose.yml logs -f node"
echo "  Логи Caddy: journalctl -u caddy -f"
echo ""
echo "Если нужно перенести БД + видео с dev — запусти 04-import-to-vps.sh"
echo "================================================="
