# FeelYoga — деплой dev-инстанса

Текущий dev-инстанс: **https://feelyoga-dev.vaibkod.online/**

## Архитектура запроса

```
браузер
  ↓ HTTPS
Caddy админа debianOCR (/etc/caddy/Caddyfile)
  ↓ reverse_proxy localhost:8880
nginx-proxy (~/projects/nginx-proxy, container nginx-proxy)
  ↓ proxy_pass http://feelyoga-nginx:80 (docker network nginx-proxy)
Orbita nginx (~/projects/feelyoga, container feelyoga-nginx)
  ↓ fastcgi_pass php-fpm:9000   (API через /api/)
  ↓ proxy_pass node:3000        (SSR Nuxt)
Orbita backend (php-fpm + mariadb + redis + manticore)
```

## Слои конфигурации (что где)

### 1. Caddy админа — `/etc/caddy/Caddyfile`
Доступ только через `sudo` (Денис вручную, MCP не может без tty).
Добавленный блок: `deploy/caddy/feelyoga.snippet`

```caddy
feelyoga-dev.vaibkod.online {
    reverse_proxy localhost:8880
}
vaibkod.online, www.vaibkod.online {
    reverse_proxy localhost:8880
}
```

### 2. Денисов nginx-proxy — `~/projects/nginx-proxy/config/feelyoga-dev.vaibkod.online.conf`
Полная копия: `deploy/nginx-proxy/feelyoga-dev.vaibkod.online.conf`
- `client_max_body_size 5G` — под видео-аплоад
- WebSocket support через map с уникальным именем `$ws_feelyoga_upgrade` (чтобы не коллизить с tube.sochispirit.com.conf)
- `proxy_pass http://feelyoga-nginx:80` — резолвится через docker DNS внутри `nginx-proxy` сети

### 3. Orbita repo — `~/projects/feelyoga/` (clone https://github.com/bezumkin/orbita.git)
- `.env` — конфиг с секретами (не в git). Шаблон: `deploy/.env.example`
- `docker-compose.override.yml` — копия `deploy/docker-compose.override.yml`
  - `container_name: feelyoga-nginx` (резолв в `nginx-proxy` сети)
  - `ports: !reset []` — не публикуем порт на хост (всё через docker network)
  - `networks.nginx-proxy.aliases: [feelyoga-nginx]` — на всякий случай
  - `networks.default.name: feelyoga_default` — изоляция от других compose-проектов

## Грабли (зафиксированы)

1. **Локальный порт 8081 был занят** другим процессом на 127.0.0.1 → решили через `ports: !reset []` в override (Compose v2.20+).
2. **map `$connection_upgrade`** уже определён в `tube.sochispirit.com.conf` → использовали уникальное `$ws_feelyoga_upgrade`.
3. **Первый запрос на Nuxt SSR — 10+ секунд** (cold start). Сразу при первом curl видим 499 timeout, потом всё ок.
4. **NAT hairpin** — с debianOCR `curl https://feelyoga-dev.vaibkod.online` не работает (сервер не достучится до своего же публичного IP). Проверять через внешний firecrawl/браузер.
5. **sudo через MCP** падает без tty — `sudo tee/cp` для Caddyfile Денис делает вручную из SSH.

## Развёртывание с нуля (рецепт для миграции на Timeweb VPS)

```bash
# 1. Клонировать orbita
cd ~/projects
git clone https://github.com/bezumkin/orbita.git feelyoga
cd feelyoga

# 2. .env
cp <ваш-готовый-env> .env   # или взять как baseline deploy/.env.example и подставить секреты

# 3. override
cp <repo>/deploy/docker-compose.override.yml ./docker-compose.override.yml

# 4. Поднять
docker compose up -d

# 5. nginx-proxy (если он используется на новом сервере)
cp <repo>/deploy/nginx-proxy/feelyoga-dev.vaibkod.online.conf ~/projects/nginx-proxy/config/feelyoga.<prod-domain>.conf
# заменить server_name и proxy_pass под прод-домен
docker exec nginx-proxy nginx -s reload

# 6. Caddy / TLS — зависит от того, какой reverse-proxy на VPS
#    На Timeweb обычно ставится свой Caddy или Nginx + certbot
```

## Миграция данных с debianOCR → Timeweb VPS

```bash
# на debianOCR
cd ~/projects/feelyoga
docker compose down
tar czf feelyoga-data-$(date +%F).tar.gz docker/mariadb upload .env

# scp на VPS, распаковать, поднять
```

## Админка

- URL: `https://feelyoga-dev.vaibkod.online/admin`
- Дефолт: `admin / admin` (**сменить сразу**)
- Настройки сайта: Settings → Site (title, description, цвета)
- Платежи: Settings → Payments (Tbank ключи когда придут)
