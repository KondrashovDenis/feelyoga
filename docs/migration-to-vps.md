# Миграция FeelYoga: debianOCR → standalone VPS

Документ для **тренировки** переноса на free-tier reg.облако VPS
(1 vCPU / 1 GB RAM / 10 GB / Debian 12). Те же шаги применимы к
будущему **проду на Timeweb VPS РФ-зоны** (более производительному).

## Архитектурное отличие от dev

На debianOCR — Caddy админа + общий nginx-proxy + наши контейнеры в shared network.
На VPS у нас root → **Caddy ставится нативно через apt**, проксирует прямо в Orbita nginx
через `localhost:NGINX_PORT`. Никакого nginx-proxy слоя.

```
Браузер
  ↓ HTTPS (Let's Encrypt автоматом)
Caddy (нативно через apt)
  ↓ reverse_proxy localhost:8080
Orbita nginx (docker, ports: 127.0.0.1:8080:80)
  ↓
php-fpm + Nuxt + MariaDB + Redis + Manticore
```

## Что нужно от Дениса перед стартом

1. **SSH-доступ к VPS** под root (через панель reg.ru). Сохрани IP и пароль/ключ.
2. **Домен** — поддомен на любом из твоих доменов. Например `vps.vaibkod.online`.
   DNS A-запись → IP VPS (можно сделать заранее, пропагация ~5 минут).
3. **(Опционально) GitHub deploy-key** для приватного репо feelyoga — или будем
   юзать `git clone https://<TOKEN>@github.com/...` через PAT.

## Шаги

### 1. Зайти на VPS

```bash
ssh root@195.208.2.136
```

### 2. Bootstrap (Docker + Caddy + swap + ufw + fail2ban)

```bash
# Получить установочный скрипт (один из вариантов):
curl -fsSL https://raw.githubusercontent.com/KondrashovDenis/feelyoga/main/deploy/scripts/01-install-vps.sh -o 01.sh
# либо git clone, либо scp скрипта с локалки

bash 01.sh
```

**Что делает:** apt update, swap 2GB (vm.swappiness=10), Docker CE, Docker Compose plugin,
Caddy через официальный репо, UFW (22/80/443), fail2ban.

**Идемпотентно** — можно перезапустить без последствий.

**Проверка:**
```bash
docker --version          # 26.x.x или новее
caddy version             # 2.x
free -h                   # должно быть Swap: 2.0G
ufw status                # active, 22/80/443 разрешены
```

### 3. DNS

В панели reg.ru (или где у тебя домен) добавь A-запись:
```
vps.vaibkod.online  →  195.208.2.136
```

Проверь резолв:
```bash
dig +short vps.vaibkod.online    # должно вернуть IP VPS
```

### 4. Установить FeelYoga

```bash
curl -fsSL https://raw.githubusercontent.com/KondrashovDenis/feelyoga/main/deploy/scripts/02-install-feelyoga.sh -o 02.sh
bash 02.sh
# Введёт промпт: домен (vps.vaibkod.online), email (denciaopin@gmail.com)
```

**Что делает:**
1. git clone bezumkin/orbita → /opt/feelyoga
2. git clone наш feelyoga config → /tmp/...
3. Накладывает overlay (наши Vue компоненты + SCSS) на /opt/feelyoga/frontend
4. Кладёт docker-compose.override.standalone.yml (только hairpin-fix, без nginx-proxy)
5. Генерирует .env с свежими секретами из .env.standalone.template
6. `docker compose pull + up -d` (5-10 минут — Nuxt билд)
7. chown www-data /vesp/{upload,tmp,log}
8. Прописывает Caddyfile, `systemctl reload caddy`

**Проверка через 5-10 минут:**
```bash
docker compose -f /opt/feelyoga/docker-compose.yml ps    # все 6 up
curl -sI https://vps.vaibkod.online/                     # HTTP/2 200
```

Заходи в браузере: `https://vps.vaibkod.online/`. Получишь чистую Orbita с нашим брендингом
(Manrope, шалфей, filippov.yoga). Контента нет — БД пустая, дефолт `admin/admin`.

### 5. (Опционально) Перенести контент с debianOCR

#### На debianOCR:
```bash
ssh debianOCR
bash <(curl -fsSL https://raw.githubusercontent.com/KondrashovDenis/feelyoga/main/deploy/scripts/03-export-from-dev.sh)
# создаст /tmp/feelyoga-migration-YYYY-MM-DD/ с db.sql + upload.tar.gz + env.txt
```

Дамп БД делается **онлайн** через `mariadb-dump --single-transaction` — без downtime.

#### Перенести на VPS:
```bash
# с debianOCR
scp -r /tmp/feelyoga-migration-* root@195.208.2.136:/tmp/
```

#### На VPS:
```bash
bash /opt/feelyoga/04-import-to-vps.sh /tmp/feelyoga-migration-2026-05-15
```

**Что делает:** импорт `db.sql` в MariaDB → распаковка `upload.tar.gz` → chown www-data → рестарт node+php-fpm.

После этого VPS-инстанс = точная копия debianOCR. **Включая пароли пользователей** (БД та же).

### 6. Проверка

```bash
# контейнеры
docker compose -f /opt/feelyoga/docker-compose.yml ps

# логи (с timeout — глобальное правило!)
docker compose -f /opt/feelyoga/docker-compose.yml logs --tail 50 node
docker compose -f /opt/feelyoga/docker-compose.yml logs --tail 50 php-fpm

# Caddy
systemctl status caddy
journalctl -u caddy -n 20 --no-pager

# RAM / Swap
free -h
docker stats --no-stream    # сколько каждый контейнер ест
```

## Откат (rollback)

```bash
cd /opt/feelyoga
docker compose down
# вернуться к чистому dev-инстансу:
docker compose up -d
# фикс прав:
docker compose exec php-fpm chown -R www-data:www-data /vesp/upload /vesp/tmp /vesp/log
```

debianOCR-инстанс остаётся **нетронутым** на всё время теста.

## Что специально НЕ настроено (для тренировки)

- **Бэкапы** (cron + restic/borg) — добавишь сам при необходимости
- **SMTP relay** — отключён, на free-tier 25/465 порты блокированы провайдером
- **Tbank эквайринг** — ждём реквизиты от Михаила
- **Мониторинг** (Prometheus/Grafana) — для теста не нужен

## Переход на Timeweb VPS

Те же скрипты, тот же флоу. Отличия:
- Лучшее железо (рекомендую минимум **2 vCPU / 4 GB RAM / 40 GB SSD**)
- Возможно другие SMTP-ограничения — проверить у провайдера
- DNS: домен заказчика (например `filippov.yoga`)
- SMTP relay: настроить через Resend или Yandex Mail (порт 587 submission)

## Грабли которые могут встретиться

См. соответствующие карточки в `~/.claude/memory/` глобальной памяти:
- `reference_hairpin_ssr_hang.md` — SSR-fetch на свой публичный домен из docker
- `reference_docker_compose_external_network.md` — на VPS не применимо (нет shared network)
- `feedback_sudo_no_tty_via_mcp.md` — на VPS Денис root, проблемы с sudo нет

Локальные грабли проекта:
- `upload/tmp/log` создаются под root → нужен `chown www-data` (скрипт это делает)
- Первый SSR-запрос на холодный Nuxt — 10+ секунд (норма, прогревается)
- Транскодинг на 1 vCPU очень медленный (50× медленнее чем на 4-ядерном)
