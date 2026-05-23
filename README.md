# FeelYoga

[![Build & Deploy](https://github.com/KondrashovDenis/feelyoga/actions/workflows/deploy.yml/badge.svg)](https://github.com/KondrashovDenis/feelyoga/actions/workflows/deploy.yml)

Платформа онлайн-курсов для преподавателя йоги Михаила Филипова.

- **Прод:** https://filippov.yoga (Timeweb VPS, РФ)
- **Dev:** https://feelyoga-dev.vaibkod.online (debianOCR)
- **Движок:** [Orbita](https://github.com/bezumkin/orbita) — self-hosted Patreon-аналог (PHP/Slim + Nuxt 3 + MariaDB + Manticore + Redis)

## Структура

- `CLAUDE.md` — контекст проекта для Claude Code
- `MEMORY.md` — индекс решений и грабель
- `deploy/customizations/` — overlay поверх upstream Orbita:
  - `frontend/` — наши `nuxt.config.ts`, `plugins/sentry.client.ts`, кастомные `components/` и `pages/`
  - `core/` — наш `bootstrap.php` (Sentry init), `Services/Mail.php` (SMTP overlay)
- `deploy/docker-compose.override.standalone.yml` — override для VPS (pre-built mode + resource limits)
- `deploy/.env.example` — шаблон `.env` для нового деплоя
- `deploy/scripts/` — bootstrap-скрипты для миграции на VPS
- `.github/workflows/deploy.yml` — CI/CD (build + scp + atomic swap + healthcheck/rollback)

## Деплой

**Автоматический через GitHub Actions** — `push` в `main` с правками в `deploy/customizations/**` или самом workflow запускает прогон:

1. `git clone` upstream Orbita по pinned commit (`ORBITA_REF` в workflow `env`)
2. Применить overlay поверх (`cp -r deploy/customizations/...`)
3. `sed`-патч i18n под ФЗ-152 формулировку согласия
4. `npm ci` + установка `@sentry/browser` поверх + `nuxt build` (на ubuntu-latest runner)
5. tarball `.output/` → `scp` на VPS
6. Atomic swap (`mv .output → .output.prev`, распаковать новый, restart `node` + `php-fpm`)
7. Healthcheck `https://filippov.yoga/` → 200 за 20 сек, иначе rollback на `.output.prev`

### Требуемые GitHub Secrets

| Name | Что | Где взять |
|---|---|---|
| `VPS_HOST` | `5.129.240.144` | — |
| `VPS_USER` | `deploy` | — |
| `VPS_SSH_KEY` | приватный ed25519 deploy-ключ | `ssh vaibkod-vps "cat ~/.ssh/github_feelyoga"` |
| `NUXT_PUBLIC_SENTRY_DSN` | DSN GlitchTip-проекта №2 | `grep ^NUXT_PUBLIC_SENTRY_DSN /opt/projects/feelyoga/.env` |

### Ручной запуск

Actions → Build & Deploy → **Run workflow** (использует `workflow_dispatch`).

## Стек на проде

| Сервис | Назначение | mem_limit |
|---|---|---|
| `feelyoga-php-fpm-1` | Orbita PHP backend (Slim) | 512m |
| `feelyoga-node-1` | Nuxt SSR (pre-built `.output/`) | 512m |
| `feelyoga-nginx-1` | upstream nginx → `127.0.0.1:8081` → Caddy на хосте | 64m |
| `feelyoga-mariadb-1` | БД (`vesp`) | 512m |
| `feelyoga-manticore-1` | Поиск | 128m |
| `feelyoga-redis-1` | Кеш | 96m |

## Платежи

Tbank (ИП Михаила Филипова, T-Bank business). Реквизиты эквайринга добавляются в `.env` при готовности (`PAYMENT_TBANK_TERMINAL` + `PAYMENT_TBANK_PASSWORD`).
