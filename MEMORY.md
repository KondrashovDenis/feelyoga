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
- **2026-05-15**: при первом запуске Orbita папки `upload/`, `tmp/`, `log/` создались под root и PHP внутри контейнера (www-data UID=33) не мог писать — ошибка `mkdir(): Permission denied` при загрузке файлов через админку. Фикс: `docker exec feelyoga-php-fpm-1 chown -R www-data:www-data /vesp/upload /vesp/tmp /vesp/log`. Делать сразу после `docker compose up -d` на новом инстансе.
- **2026-05-15**: путь к картинкам в Orbita — `GET /api/image/<uuid>?w=&h=&fit=crop&fm=webp`, **не** `/i/<uuid>` (это короткий редирект на `/topics/<uuid>` 302). Видео — аналогично через `/api/video/<uuid>`. Используется imagick для ресайза on-demand.
- **2026-05-17**: deploy Orbita на слабый VPS (1vCPU/1GB/10GB) — `npm i + nuxt build` НЕ влезает в 10GB диск (containerd overlayfs съедает всё до 100%). Симптом: node exit code 1, OOMKilled=false, docker logs пусто. Решение — **pre-built deployment**: собрать `.output/` на dev-машине (debianOCR), упаковать `tar -czf` (~4-30MB), скопировать на VPS, override compose `command: node ./.output/server/index.mjs` без npm/build. Свой get-api.js hairpin-фикс при этом запекается в bundled chunks ещё на этапе build (видно `SITE_URL = "http://nginx/"` в `.output/server/chunks/nitro.mjs`). На VPS остаётся только runtime ≈ 80MB RAM.
- **2026-05-17**: swap 2GB на 10GB диск — слишком жирно (20% диска). Для VPS с малым диском swap 512MB достаточно, остальное освобождает место под Docker.

## VPS-инстанс (2026-05-17, тренировочный)
- **URL:** https://vps.vaibkod.online/ — 200 OK, тот же UI что dev
- **Хост:** reg.облако Free Tier, 1vCPU/1GB/10GB, Debian 12, IP 195.208.2.136
- **Архитектура:** Caddy нативно через apt (без nginx-proxy слоя), reverse_proxy localhost:8080
- **Deploy режим:** pre-built — `.output/` собран на debianOCR, скачан через https://vaibkod.online/feelyoga-output.tar.gz, на VPS только runtime
- **Свободно на диске после деплоя:** ~3GB из 10GB
- **Не для прода Михаила** — для Михаила минимум 2vCPU/4GB/40GB SSD на Timeweb

## Состояние deploy (2026-05-15, конец дня)
- **Dev-инстанс Orbita:** https://feelyoga-dev.vaibkod.online/ — 200 OK, locale=ru
  - Кастомизация применена: navbar=`filippov.yoga` (Manrope 200), widgets/author=`filippov.yoga`, footer=`Разработка сайта vaibkod.ru`, убран "Сделано на Орбите", шрифт Manrope, акцент шалфея `#6b8e6b`
  - В админке: title="Filippov Yoga", description="Онлайн-практики от Михаила Филиппова", copyright="Михаил Филиппов", started=2026-05-15
  - Загружены: poster (47bc7558...), background (de2a2fcc...), cover (c48584b0...)
  - Создан топик "Название видео" + загружены 2 видео (одно прицеплено, "Видео с чайной церемонией" — отдельный файл)
  - Уровень подписки "Студент" — 100₽/мес
- **HTML-моки на vaibkod.online:**
  - `/` — индекс с тремя ссылками
  - `/v1/` — Serif (Cormorant Garamond + Inter) editorial-стиль
  - `/v2/` — Sans (Onest) bento-сетка
  - Все три тянут одни картинки из админки Orbita через `/api/image/<uuid>?w=&h=&fit=crop&fm=webp`
- **6 контейнеров up:** feelyoga-{mariadb,manticore,nginx,node,php-fpm,redis}, COMPOSE_PROJECT_NAME=feelyoga
- **Caddy админа:** блоки `feelyoga-dev.vaibkod.online` + `vaibkod.online`/`www.vaibkod.online` → `localhost:8880`
- **nginx-proxy:** vhosts `feelyoga-dev.vaibkod.online.conf` + `vaibkod.online.conf` (file_server для моков). Volume `feelyoga-mockups/site:/var/www/feelyoga-mockups:ro`.
- **TLS:** Let's Encrypt автоматом
- **Админка:** `/admin` — Денис сменил пароль

## Что ждём (next session)
1. **Михаил выбирает** один из 3 вариантов (или гибрид)
2. **Михаил доделывает контент:** прицепить второе видео к топику, дать имя топику ("Название видео" — плейсхолдер), оформить страницу "Обо мне", залить ещё видео
3. **Tbank-эквайринг** — реквизиты `PAYMENT_TBANK_TERMINAL` + `PAYMENT_TBANK_PASSWORD` в `.env`

## Что делаем когда придёт ответ
- Путь A (эволюционная кастомизация): переписываем `pages/index.vue` под выбранный мок, финализируем шрифт+палитру в `_variables.scss`, переоформляем `components/topic/card.vue`, мобильная версия. Оценка: 2-3 дня.
- Не забыть: проверить корректность смены `data-bs-theme="dark"` с нашими SCSS-переменными (тёмная палитра требует отдельного `[data-bs-theme="dark"]` блока — пока не сделано).
