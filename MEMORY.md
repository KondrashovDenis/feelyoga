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
- **URL:** https://vps.vaibkod.online/ — 200 OK, полный клон dev (после import-data-vps.sh)
- **Хост:** reg.облако Free Tier, 1vCPU/1GB/10GB, Debian 12, IP 195.208.2.136
- **Архитектура:** Caddy нативно через apt (без nginx-proxy слоя), reverse_proxy localhost:8080
- **Deploy режим:** pre-built — `.output/` собран на debianOCR, скачан через https://vaibkod.online/feelyoga-output.tar.gz, на VPS только runtime
- **Свободно на диске после деплоя:** ~3GB из 10GB
- **Не для прода Михаила** — для Михаила минимум 2vCPU/4GB/40GB SSD на Timeweb

## Выбор дизайна (2026-05-17)
- **Михаилу зашёл v1 (Serif)** из 3 вариантов на vaibkod.online
- В Orbita портируется **поэтапно**: Phase A (шрифт+палитра, без кода) → Phase B (новый pages/index.vue с full-width hero/about/pricing) → Phase C (editorial карточки топиков)
- **Phase A сделана:** Cormorant Garamond + Inter, акцент олива `#6b7d5f`, warm off-white `#fafaf8`, navbar/widget brand с serif italic, добавлен dark-theme override
- **Архитектура контента** для админ-редактирования: тексты hero/about/pricing-intro в `pages` Orbita (с alias `home-*`, position=none — не появляются в навигации), редактируются Михаилом через EditorJS в `/admin/pages`. Pricing — `levels` (уже есть). Картинки — `settings.poster/background/cover` (уже есть). **Ноль новых полей** добавлять в админку не надо.

## Готовый скилл для будущих миграций
- `~/.claude/skills/vps-migration/SKILL.md` — собран из всего опыта FeelYoga
- Триггерится на "перенести на VPS / deploy на Timeweb / переехать с debianOCR"
- Двухрежимный install (prebuilt/build), 4 фазы, 9 pitfalls, шаблон-проект `KondrashovDenis/feelyoga`
- Применять при переезде на прод-Timeweb для Михаила или для других проектов Дениса

## Решения от 2026-05-22
- **Email-форвард `info@filippov.yoga` + `admin@filippov.yoga`:** `info@` → `holod111@yandex.ru` (Михаил, личная) + копия на `admin@filippov.yoga` (Денис). `admin@filippov.yoga` — публикуется на сайте как контактный, существует в VK Workspace, форвардится на `denciaopin@gmail.com`. Поток входящих от пользователей будет редким — Михаил основную коммуникацию ведёт в соцсетях.
- **Хранилище медиа и бэкапы — двухуровневая стратегия:**
  - **S3 в РФ** (Timeweb S3 / Selectel) — основное хранилище медиа для FeelYoga (видео Михаила), Момарус (фото картин), ПетПаркинг (фото/видео животных). Туда же — горячие бэкапы БД для быстрого восстановления (минуты-часы). Локация РФ → ФЗ-152 OK.
  - **B2 (Backblaze, не РФ)** — disaster recovery: полный краш VPS Timeweb / уход провайдера. Это **резервная копия**, не активная обработка → формально под ФЗ-152 это техническое резервирование, не передача персданных за рубеж; риск низкий.
  - **Когда брать S3:** как только Михаил пришлёт первые видео (тогда же — точка для платёжа за S3). До этого момента — медиа в локальном `upload/`, бэкапы только B2.
  - **Распределение:** разные проекты (feelyoga, momarus, petparking) делят один S3-bucket пространством, но изолированы префиксами / отдельными bucket'ами.

## ФЗ-152 / Sentry / CI (2026-05-22)
- **GlitchTip self-hosted** живёт на самом VPS Vaibkod1 (`errors.infra.vaibkod.online` → 5.129.240.144). Не на debianOCR. 4 контейнера: `glitchtip-{web,worker,postgres,redis}`. Данные не покидают тот же VPS, что и БД FeelYoga → ФЗ-152 OK.
- **Sentry PHP SDK** установлен в overlay (`deploy/customizations/core/bootstrap.php` + composer `sentry/sentry ^4.27`). PII принудительно `false`, query/cookies/headers вырезаются в `before_send`. Smoke-test пройден, event прилетает в GlitchTip.
- **Sentry Nuxt SDK** — `@sentry/browser` подгружается в CI (`npm install --no-save @sentry/browser@^8.40.0`) + overlay `plugins/sentry.client.ts`. Overlay nuxt.config.ts добавляет `runtimeConfig.public.SENTRY_*`. Активен после первого CI deploy.
- **GitHub Actions CI/CD** — `.github/workflows/deploy.yml`. Триггер: push в `main` с правками `deploy/customizations/**` или сам workflow. Шаги: clone upstream@ORBITA_REF=5526daa → apply overlay → patch i18n register_agree (sed) → `npm ci + sentry browser + nuxt build` → tarball → scp на VPS → atomic swap `.output` → restart node/php-fpm → healthcheck с rollback.
- **GH Secrets для CI:** `VPS_SSH_KEY` (приватный ed25519, забрать через `ssh vaibkod-vps "cat ~/.ssh/github_feelyoga"`), `VPS_HOST=5.129.240.144`, `VPS_USER=deploy`. Pub-часть ключа уже добавлена в `/home/deploy/.ssh/authorized_keys` на VPS.
- **Privacy policy** — `app_pages` id=4, alias=privacy. Доступна по `/pages/privacy` (200 OK) и `/api/web/pages/privacy`. Текст заготовлен под ФЗ-152, placeholders `[ФИО]`, `[ОГРНИП]`, `[ИНН]`, `[email]` Михаил заполнит когда даст реквизиты ИП.
- **Чекбокс согласия при регистрации** — активирован через `REGISTER_USER_AGREEMENT=/pages/privacy` в `.env`. UI чекбокс уже встроен в `frontend/src/components/app/login.vue` upstream (через `v-if="userAgreement"`). Серверный гард `Register::post()` блокирует POST без `agree=true`. Текст под ФЗ-152 («Я даю согласие…») придёт после первого CI build (sed-патч в workflow).
- **Юридический трек до запуска платежей** (не блокирует разработку): договор оператор↔обработчик между ИП Михаила (оператор) и Денисом (обработчик/владелец VPS), либо переоформление аккаунта Timeweb на Михаила. Уведомление в РКН от ИП. См. handoff `2026-05-20` для контекста.

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

## Backlog для следующих сессий

### Открытые задачи (по приоритету)
1. **Ждём Михаила** — финальные тексты hero/about/subscription через `/admin/pages` + видео-контент (он залил пока 1 placeholder-видео)
2. **Sentry/GlitchTip SDK подключение** — DSN в `.env` уже есть, composer-пакет `sentry/sentry` для PHP и `@sentry/nuxt` для frontend ещё **не установлены**. Делать как отдельную сессию когда понадобится — пример настройки в `~/.claude/projects/D--Claude-petparking/memory/project_email_stack_*.md` (там полный pattern для Django, для Orbita аналогично).
3. **`info@filippov.yoga` ящик в VK admin** — создать когда Михаил скажет на какой адрес форвардить (его yandex или другой).
4. **Fix baked-in SITE_URL в og:image** (Task #6 в task tracker) — при следующем перебилде на debianOCR подменить `SITE_URL=https://filippov.yoga/` в `.env` перед `npm run build`, иначе og:image указывает на dev-домен.
5. **GitHub Actions CI/CD** — обсуждали, отложили на после email pipeline. Файл `.github/workflows/build-and-deploy.yml` уже спланирован: push в main → build .output на ubuntu-latest → scp на VPS → recreate node. Нужен `VPS_SSH_KEY` в GH Secrets.
6. **Tbank-эквайринг** — реквизиты `PAYMENT_TBANK_TERMINAL` + `PAYMENT_TBANK_PASSWORD` в `.env` (от Михаила когда заведёт интернет-эквайринг).

### Roadmap по разработке
- Когда Михаил пришлёт реальные тексты — править через `/admin/pages` напрямую (placeholder в `home-hero`, `subscription-intro`, `about` уже заведены). **Кода трогать не надо.**
- Когда зальёт видео — раскидать по 4 категориям (`practice`/`courses`/`meditation`/`pranayama`) через `/admin/topics`.
- Если попросит правки структуры layout/новые секции/правки шрифтов — переписываем компоненты в `deploy/customizations/frontend/...` локально → git push → apply на debianOCR → перебилд .output → upload на VPS.

### Известные проблемы / технический долг
- `og:image` указывает на `https://feelyoga-dev.vaibkod.online/...` (запеклось при build) — Task #6
- `data-bs-theme="dark"` блок в SCSS есть, но визуально не протестирован на проде (нет ученика чтобы пощёлкал переключатель темы — проверим позже)
- Sentry events не доходят — SDK не подключён

## Email pipeline активен (2026-05-20, конец дня)
- **Отправка:** VK Workspace SMTP через `noreply@filippov.yoga` (`smtp.mail.ru:587 TLS`, app-password 16 chars).
- **Smoke-test пройден:** оба теста доставлены во входящие (gmail + mail.ru), не в спам.
- **DNS-записи под почту filippov.yoga (все в reg.ru):**
  - `@` TXT `mailru-domain: 12VMwWFuW0bJzpD7` ← VK verify
  - `@` MX `emx.mail.ru.` (priority 10) ← VK приём
  - `@` TXT `v=spf1 include:_spf.mail.ru include:spf.unisender.ru ~all` ← combined SPF (VK + UniSender)
  - `@` TXT `unisender-go-validate-hash=043c6a25fd905b56e5898614dcf25d25` ← UniSender verify (не используется сейчас, но остался на будущее)
  - `mailru._domainkey` TXT `v=DKIM1; k=rsa; p=...` ← VK DKIM (234 chars)
  - `us._domainkey` TXT `v=DKIM1; k=rsa; p=...` ← UniSender DKIM (не используется сейчас)
  - `_dmarc` CNAME `filippov.yoga.dmarc.unisender.ru.` ← DMARC делегирован UniSender
- **`.env` SMTP блок** на VPS: `SMTP_HOST=smtp.mail.ru`, `SMTP_USER=noreply@filippov.yoga`, `SMTP_PORT=587`, `SMTP_PROTO=tls`, `SMTP_USER_NAME=FeelYoga`, `SMTP_PASS=<app-password>` (только в .env на сервере, в git нет).
- **Mail.php overlay-патч** (`deploy/customizations/core/src/Services/Mail.php`): добавлена поддержка `SMTP_FROM` (fallback на `SMTP_USER`). Сейчас неактивна; останется на случай UniSender Go или похожих провайдеров.
- **Ящик `info@filippov.yoga`** для приёма — ещё не создан в VK admin; делать когда Михаил скажет на какой адрес форвардить.

## PROD (2026-05-20)
- **URL:** https://filippov.yoga (Timeweb VPS Vaibkod1, 5.129.240.144)
- **Каталог:** `/opt/projects/feelyoga/` (user `deploy`)
- **MCP:** `mcp__timeweb__bash|read_file|write_file|list_dir` (cwd по умолчанию /home/deploy)
- **Caddy snippet:** `/opt/infra/caddy/snippets/feelyoga.caddy` → `reverse_proxy 127.0.0.1:8081`
- **Архитектура контента:** база `bezumkin/orbita` + overlay из `KondrashovDenis/feelyoga` (наш fork).
- **Phase B-7 customizations** (Hero/Card/navbar/index.vue/about/subscription/search/[topics]) применены — см. `deploy/customizations/frontend/`.
- **Mode: pre-built** — `.output/` собирается на debianOCR через `docker compose exec node npm run build`, упаковывается в tar.gz, заливается на VPS в `frontend/.output/`. Node контейнер запускается за 4 сек, не билдит.
- **HIDE_WIDGETS=author,search,online,levels,categories,tags,pages** — все правые виджеты глобально скрыты.
- **Sentry DSN в .env есть** (GlitchTip self-hosted `https://errors.infra.vaibkod.online`):
  - `SENTRY_DSN` (php) → project feelyoga (ID 1)
  - `NUXT_PUBLIC_SENTRY_DSN` → project feelyoga-js (ID 2)
  - SDK композер/npm пакеты **ещё не подключены** — отдельная задача (когда понадобится).
- **SMTP пустой** на VPS — Orbita не шлёт писем. Ждём VK Workspace для filippov.yoga (привязка к почте Михаила).
- **dev-инстанс `https://feelyoga-dev.vaibkod.online/`** на debianOCR оставлен как площадка для проб (Денис: "места там хватает").

## Workflow для prod-правок (важно)
1. Правка локально в `D:\Claude\Yoga-Filippov\deploy\customizations\frontend\...`
2. `git push` в `KondrashovDenis/feelyoga` (origin)
3. Применить overlay на debianOCR: `cp -r deploy/customizations/frontend/. ~/projects/feelyoga/frontend/`
4. **Перебилдить .output на debianOCR:** `docker compose exec -T node sh -c 'cd /vesp/frontend && rm -rf .output && npm run build'`
5. **Упаковать + опубликовать tarball:** `cd ~/projects/feelyoga/frontend && tar -czf /tmp/feelyoga-output-$(openssl rand -hex 8).tar.gz .output && mv ... ~/projects/feelyoga-mockups/site/` (доступно как https://vaibkod.online/feelyoga-output-XXX.tar.gz)
6. **На VPS:** `sudo rm -rf /opt/projects/feelyoga/frontend/.output && curl -fsSL <URL> -o /tmp/out.tar.gz && tar -xzf /tmp/out.tar.gz -C /opt/projects/feelyoga/frontend/`
7. **Recreate node:** `cd /opt/projects/feelyoga && docker compose up -d --force-recreate node` (4 секунды)

## Грабли PROD (2026-05-20)
- **OOM в restart loop при mode=build на Стандарт-тарифе.** `mem_limit: 512m` на node-контейнере недостаточно для `nuxt build --vite production`. Heap уходит за 250 MB, V8 → "Ineffective mark-compacts near heap limit" → exit 134 → docker рестарт → опять npm i + build → опять OOM. RestartCount 674 за сутки. Фикс: pre-built mode (`.output/` собирается отдельно, на проде только runtime ≈ 60-80 MB).
- **Core dump 2.2 GB в `frontend/core`** при OOM-крашах node. Чистить через `sudo rm`. На будущее: настроить `ulimit -c 0` для контейнера или `kernel.core_pattern` чтобы не плодились.
- **SITE_URL запекается в `.output` при build** — при сборке на debianOCR в чанки попадает `https://feelyoga-dev.vaibkod.online/`, og:image на проде указывает на dev-домен. Решение: на debianOCR подменить SITE_URL в .env перед build, пересобрать. Task #6 в backlog.
- **`.output/` принадлежит root** (создан внутри node-контейнера) — `rm -rf .output` под `deploy` падает с Permission denied. Нужен `sudo rm`.
