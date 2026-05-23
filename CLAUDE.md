# FeelYoga

Платформа онлайн-курсов для преподавателя йоги Михаила Филипова.
Рабочее название проекта/бренда — **FeelYoga**. Финальный домен заказчик ещё не выбрал.

## Статус
Discovery → выбор пути деплоя. Заказчик хочет онлайн-инструмент для своих учеников
(продажа доступа к видеокурсам + закрытый контент), **не** публичный лендинг-визитка.
Домен заказчик ещё не выбрал.

## Что известно
- **Заказчик:** Михаил Филипов, преподаватель йоги
- **Цель сайта:** self-hosted платформа для продажи доступа к собственным видеокурсам и контенту.
  Своя персона пиарить не хочет — нужен инструмент для существующих учеников.
- **Контент:** уже снято видео + будет дальше
- **Референс по функционалу:** alexeyvladovskiy.ru *(не по сути — у него WordPress-визитка с расписанием,
  а нам нужна закрытая платформа подписочного типа)*
- **Реальный аналог по функционалу:** Patreon / Boosty / Sponsr
- **Решение по движку:** Orbita (`github.com/bezumkin/orbita`) — она же mentortube у Дениса на debianOCR
- **Хостинг dev:** debianOCR за nginx-proxy (временно, для разработки)
- **Хостинг прод:** VPS Timeweb в РФ-зоне (коммерческий проект, не должен зависеть от сервера Андрея).
  Перенос: `docker compose down` → scp `./docker/mariadb` + `./upload` + `.env` + код → `up` на VPS.
- **Git:**
  - Локально: `D:\Claude\Yoga-Filippov\` (папку не переименовываем — рабочая)
  - На debianOCR: `~/projects/feelyoga/`
  - GitHub (приватный): `https://github.com/KondrashovDenis/feelyoga.git`
- **Dev-домен:** `feelyoga-dev.vaibkod.online` (DNS на reg.ru → 84.54.188.199 debianOCR, пропагирован).
  Корень `vaibkod.online` и `www.vaibkod.online` тоже указывают на debianOCR — можно использовать для HTML-моков.

## ТЗ от заказчика (Михаил)
Прямая цитата: *«главное чтобы хорошо открывались видосики и качество было и чтобы оплата как часы работала. Все остальное нюансы и максимально просто»*.

**Дизайн-направление:** референсы lamoda.ru и balenciaga.com — но не по функционалу (это магазины), а по эстетике.
Слова Михаила: *«Белый, красивый шрифт, приятный»*. Расшифровка: минимализм, светлая палитра, аккуратная типографика, много воздуха.

**Приоритеты:**
1. Качество видеоплеера + HLS-streaming
2. Надёжная оплата (Tbank)
3. Минималистичный белый UI с хорошей типографикой
4. Всё остальное — по дефолту Orbita

## Стек (Orbita)
- PHP-FPM (кастомный образ `bezumkin/orbita-php`)
- Nginx
- MariaDB
- Node (frontend, отдельный сервис)
- Frontend: Vue/Nuxt (внутри `frontend/`)
- Уже сконфигурена под external network `nginx-proxy`
- Платёжные шлюзы из коробки: **Yookassa, Raiffeisen SBP, Tbank, Payrexx** — РФ закрыто

## Открытые архитектурные вопросы
1. **Один инстанс на каждого creator или multi-tenant?** Orbita single-creator из коробки.
   Денис изначально планировал tube.sochispirit. Значит варианты:
   - (A) Отдельный инстанс Orbita под доменом Михаила (clone из mentortube)
   - (B) Михаил — creator внутри общего sochispirit-инстанса (требует multi-tenant форк)
   - (C) Forkнуть Orbita и сделать multi-tenant для общего пула преподавателей
2. **Видеохостинг:** хранить локально на debianOCR (диск/upload-папка Orbita) или
   подключить webdav-server / внешний CDN. У Дениса уже есть `~/projects/webdav-server`
   и `~/projects/video_server` — проверить как они задействованы в mentortube.
3. **Платёжный шлюз:** какой из четырёх предпочесть для Михаила (нужна юр.форма / ИП / самозанятый).
4. **Брендинг и UI:** Orbita generic — нужна ли кастомизация (цвета, лого, тексты) или
   уйти в дефолт ради скорости запуска.
5. **Домен:** ждём от заказчика.

## План
1. ✅ Архитектура — отдельный инстанс Orbita под Михаила (multi-tenant отложен)
2. ✅ Платежи — Tbank (ИП Михаила, T-Bank business)
3. ⏳ Дождаться домена от Михаила → DNS на debianOCR (для dev)
4. ⏳ Ждать Tbank-эквайринг → `PAYMENT_TBANK_TERMINAL` + `PAYMENT_TBANK_PASSWORD`
5. Создать bare-репо на debianOCR + remote на github.com/KondrashovDenis/
6. Клонировать Orbita (или форкнуть mentortube) → `~/projects/yoga-filippov/` на debianOCR
7. Конфиг: `COMPOSE_PROJECT_NAME=feelyoga`, `container_name: feelyoga-nginx`, network alias (избежать коллизии с mentortube/sochispirit/momarus в общей nginx-proxy сети)
8. Подключить Tbank, протестировать оплату
9. Залить 10 видео Михаила, проверить HLS-транскодинг
10. Кастомизация frontend под "белый минимализм" с хорошей типографикой
11. **Когда продакт стабилизируется → миграция на VPS Timeweb РФ**

## Конвенции
- Язык интерфейса: русский
- Деплой: контейнер на debianOCR за nginx-proxy (паттерн как у momarus/sochispirit)
- Hand-off между сессиями: `.claude-handoff.md` (в `.gitignore`)

## Секреты и vault — обязательное правило
**Единственный рабочий `.env` проекта:** `/opt/projects/feelyoga/.env` на VPS Vaibkod1 (5.129.240.144, user `deploy`).
Денис ведёт зашифрованный vault, в который копирует значения секретов из этого файла.

**Правило для Claude — обязательное, не пропускать:**
Если в рамках сессии в этот `.env` **добавляется новый ключ** или **меняется значение существующего секрета** (ротация пароля, новый DSN/токен/SMTP-пасс и т.п.) — Claude обязан **явно предупредить Дениса в чате** с указанием:
- какой ключ затронут (`SENTRY_DSN`, `SMTP_PASS` и т.п.)
- что произошло (added / value-changed)
- (для added) что туда положено по смыслу — без цитирования самого секретного значения

Денис после предупреждения **сам** возьмёт актуальное значение через `ssh vaibkod-vps "cat /opt/projects/feelyoga/.env"` и обновит свой vault. Claude **не** должен цитировать значения секретов в чате (правило `feedback_secrets_in_chat.md`).

Триггеры на которые обязательно срабатывать:
- любая запись/append в `/opt/projects/feelyoga/.env`
- запуск скриптов которые **могут** дописать в `.env` (composer scripts, install scripts, миграционные хелперы)
- генерация новых ключей/паролей которые потом пойдут в `.env`

## Ключевые команды
```bash
# на debianOCR
cd ~/projects/feelyoga
docker compose ps
docker compose logs -f nginx --tail 50    # с timeout — никогда без!
docker compose up -d
docker compose down

# nginx-proxy reload после правки vhost
docker exec nginx-proxy nginx -s reload

# админка Orbita
# https://feelyoga-dev.vaibkod.online/admin (login: admin / pass: admin по умолчанию — СМЕНИТЬ)
```

## Связанные глобальные правила
- `reference_docker_compose_external_network.md` — `container_name`/`aliases` для shared nginx-proxy сети
- `reference_yandex_metrika_gotchas.md` — если будет Метрика на лендинг-обложке
- `reference_telegram_deep_link_auth.md` — если делать вход через TG (у Михаила скорее всего есть учеников TG-чат)

## Конвенции
- Язык интерфейса: русский
- Деплой: контейнер на debianOCR за nginx-proxy
- Аналитика: Яндекс.Метрика (см. глобальную memory `reference_yandex_metrika_gotchas.md` — `?id=` обязателен в `tag.js`)
- Hand-off между сессиями: `.claude-handoff.md` (в `.gitignore`)

## Ключевые команды
*(заполнить после выбора стека)*

## Связанные глобальные правила
- `reference_nextjs_standalone_pitfall.md` — если выберем Next.js, осторожно с `output:'standalone'`
- `reference_nextjs_use_search_params.md` — Suspense для `useSearchParams`
- `reference_yandex_metrika_gotchas.md` — Метрика
- `reference_docker_compose_external_network.md` — при подключении к shared external network
