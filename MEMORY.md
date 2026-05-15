# FeelYoga — память проекта

Индекс решений, гипотез и грабель. Карточки складывать в `memory/` (создать при первой записи).

## Решения
- **2026-05-15**: движок — Orbita (`github.com/bezumkin/orbita`), он же mentortube. Self-hosted Patreon-аналог. Лендинг-визитка не делаем — заказчику не нужен.
- **2026-05-15**: РФ-платежи закрыты из коробки: Yookassa, Raiffeisen SBP, Tbank, Payrexx (для подписок).
- **2026-05-15**: архитектура — **отдельный инстанс под Михаила** на его домене (клон mentortube). Multi-tenant — отложен на потом, если придёт второй creator.
- **2026-05-15**: платёжный шлюз — **Tbank** (у Михаила ИП + T-Bank business).
- **2026-05-15**: на старт уже есть ~10 готовых видео Михаила (загружать в первый запуск).
- **2026-05-15**: брендинг — белый минимализм + красивая типографика. Референсы: lamoda.ru, balenciaga.com (берём эстетику, не функционал — магазины тут ни при чём).
- **2026-05-15**: dev на debianOCR, **прод на VPS Timeweb РФ** (коммерческий проект, не на чужом сервере). Перенос через docker compose (volumes: mariadb + upload).
- **2026-05-15**: ТЗ от заказчика короткое — видео + оплата, остальное "максимально просто". Не пилить лишнее.
- **2026-05-15**: рабочее название проекта/бренда — **FeelYoga**. Локальная папка остаётся `D:\Claude\Yoga-Filippov\` (не переименовываем). На сервере и в git — `feelyoga`. Финальный публичный домен заказчик ещё не выбрал.
- **2026-05-15**: GitHub repo создан (приватный): `https://github.com/KondrashovDenis/feelyoga.git`.
- **2026-05-15**: Dev-домен — `feelyoga-dev.vaibkod.online` (свободный домен Дениса). DNS на reg.ru → 84.54.188.199, пропагирован. Записи: `@`, `www`, `feelyoga-dev` все → debianOCR.
- **2026-05-15**: путь к согласованию дизайна — расклад (A):
  1. Orbita с кастомизированным белым минимализмом на `feelyoga-dev.vaibkod.online`
  2. HTML-мок №1 с serif-типографикой (Cormorant)
  3. HTML-мок №2 с современным sans (Manrope или Onest)

## Открытые вопросы
- **Видеохостинг:** локальный upload Orbita vs webdav-server (~/projects/webdav-server) vs ~/projects/video_server. Решить после оценки объёма 10 видео.
- **Домен:** ждём от заказчика.
- **Tbank терминал:** Михаил подаёт заявку на интернет-эквайринг → получает `PAYMENT_TBANK_TERMINAL` + `PAYMENT_TBANK_PASSWORD` для `.env`.
- **Frontend кастомизация:** оценить объём правки `frontend/` под референсы.

## Гипотезы
- mentortube на debianOCR **запущен** 3 недели как `tube.sochispirit.com`. 6 контейнеров up. Это рабочий референс-инстанс, не сырьё.
- Orbita из коробки умеет HLS-транскодинг ffmpeg (5 разрешений 240p→4K), Manticore поиск, многоязычие. Под "качество видео" из ТЗ — уже закрыто без доработок.
- У Дениса есть `~/projects/webdav-server` и `~/projects/video_server` — потенциально для отдельного видеохранилища (не нужно на старте, 10 видео ≈ 5-10GB локально)

## Грабли
- **2026-05-15**: локальный порт 8081 на хосте уже занят → в override `ports: !reset []` (Compose v2.20+). Не публикуем nginx-orbita на хост вообще, всё через docker network.
- **2026-05-15**: `map $connection_upgrade` уже определён в `tube.sochispirit.com.conf` nginx-proxy → у нас уникальное имя `$ws_feelyoga_upgrade`. Иначе nginx ругается на duplicate map.
- **2026-05-15**: первый запрос на Nuxt SSR — 10+ секунд (cold start). Любой curl с m<10 ловит 499 timeout. Для curl-тестов min 30 сек.
- **2026-05-15**: с debianOCR `curl https://feelyoga-dev.vaibkod.online` подвисает — NAT hairpin (сервер не идёт к своему же публичному IP). Проверять снаружи через firecrawl/браузер/`curl --resolve domain:443:127.0.0.1`.
- **2026-05-15**: `sudo tee/cp` через MCP падает на tty (грабля зафиксирована глобально). Caddyfile админа правил Денис вручную из SSH.

## Состояние deploy (2026-05-15)
- **Dev-инстанс:** https://feelyoga-dev.vaibkod.online/ — **200 OK, locale=ru, дефолтный UI Orbita**
- **6 контейнеров up:** feelyoga-{mariadb,manticore,nginx,node,php-fpm,redis}, COMPOSE_PROJECT_NAME=feelyoga
- **Caddy админа:** добавлены блоки `feelyoga-dev.vaibkod.online` + `vaibkod.online`/`www.vaibkod.online` → `localhost:8880`
- **nginx-proxy:** vhost `config/feelyoga-dev.vaibkod.online.conf` → `proxy_pass http://feelyoga-nginx:80`
- **TLS:** Let's Encrypt сертификат выпущен автоматом
- **Админка:** `/admin` логин `admin / admin` — **СМЕНИТЬ при первом входе**
