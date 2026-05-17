#!/usr/bin/env bash
# 01-install-vps.sh — bootstrap чистого Debian 12 VPS под FeelYoga.
#
# Запускать на VPS под root (или через sudo).
# Идемпотентно: можно повторить безопасно.
#
# Что делает:
#   1. apt update + базовые пакеты
#   2. Swap 2 GB (критично при 1 GB RAM)
#   3. Docker + Docker Compose plugin (официальный репо)
#   4. Caddy (официальный репо)
#   5. UFW (22, 80, 443)
#   6. fail2ban (защита SSH)
#
# Не делает (это руками):
#   - SSH-ключи (Денис настраивает через панель reg.ru или ssh-copy-id)
#   - DNS-запись домена
#   - Сертификаты — Caddy сам через Let's Encrypt
#
# Использование:
#   curl -fsSL https://raw.githubusercontent.com/KondrashovDenis/feelyoga/main/deploy/scripts/01-install-vps.sh | bash
#   ИЛИ
#   bash 01-install-vps.sh

set -euo pipefail

# --- 1. Базовые пакеты ---
echo "==> apt update + базовые пакеты"
apt-get update -qq
apt-get install -y -qq \
    curl wget git ca-certificates gnupg lsb-release \
    htop tmux vim ufw fail2ban \
    debian-keyring debian-archive-keyring apt-transport-https

# --- 2. Swap 2 GB ---
if [[ ! -f /swapfile ]]; then
    echo "==> создаю swap 2GB"
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    grep -q '/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
    # vm.swappiness=10 — использовать swap только при реальной нужде
    sysctl -w vm.swappiness=10
    grep -q 'vm.swappiness' /etc/sysctl.conf || echo 'vm.swappiness=10' >> /etc/sysctl.conf
else
    echo "==> swap уже есть, пропускаю"
fi

# --- 3. Docker ---
if ! command -v docker &> /dev/null; then
    echo "==> устанавливаю Docker"
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
         https://download.docker.com/linux/debian $(lsb_release -cs) stable" \
         > /etc/apt/sources.list.d/docker.list
    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    systemctl enable --now docker
else
    echo "==> Docker уже установлен"
fi

# --- 4. Caddy ---
if ! command -v caddy &> /dev/null; then
    echo "==> устанавливаю Caddy"
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' > /etc/apt/sources.list.d/caddy-stable.list
    apt-get update -qq
    apt-get install -y -qq caddy
    systemctl enable --now caddy
else
    echo "==> Caddy уже установлен"
fi

# --- 5. UFW (открыть SSH, HTTP, HTTPS) ---
echo "==> UFW: открываю 22, 80, 443"
ufw --force reset > /dev/null
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw --force enable

# --- 6. fail2ban (защита SSH) ---
if [[ ! -f /etc/fail2ban/jail.local ]]; then
    cat > /etc/fail2ban/jail.local <<'EOF'
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = %(sshd_log)s
maxretry = 5
bantime = 1h
findtime = 10m
EOF
    systemctl restart fail2ban
    echo "==> fail2ban настроен"
fi

# --- Итог ---
echo ""
echo "================================================="
echo "✓ VPS готов:"
echo "  Docker: $(docker --version | cut -d' ' -f3 | tr -d ',')"
echo "  Caddy:  $(caddy version | cut -d' ' -f1)"
echo "  Swap:   $(free -h | grep Swap | awk '{print $2}')"
echo "  UFW:    $(ufw status | head -1)"
echo ""
echo "Следующий шаг: 02-install-feelyoga.sh"
echo "================================================="
