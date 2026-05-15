# FeelYoga mockups

HTML-моки для согласования визуального направления с заказчиком (Михаил Филиппов).

## Публичные URL

| Вариант | URL | Описание |
|---|---|---|
| 0 | https://feelyoga-dev.vaibkod.online/ | Живая Orbita с базовой кастомизацией (Manrope, шалфей, белый) |
| 1 | https://vaibkod.online/v1/ | Serif (Cormorant Garamond) — editorial / fashion стиль |
| 2 | https://vaibkod.online/v2/ | Sans (Onest) — современный геометрический, bento-сетка |
| index | https://vaibkod.online/ | Страница-индекс с тремя ссылками |

## Где живут

На debianOCR: `~/projects/feelyoga-mockups/site/{index,v1,v2}/index.html`

Раздаются через `nginx-proxy` контейнер (volume mount → `/var/www/feelyoga-mockups`).
Caddy админа роутит `vaibkod.online` и `www.vaibkod.online` → `localhost:8880` → nginx-proxy → server-блок `vaibkod.online.conf`.

## Используемые картинки

Все три мока вытягивают одни и те же изображения, загруженные через админку Orbita
(`feelyoga-dev.vaibkod.online/admin/settings`). UUID-ы:

- **Постер** (фото Будды): `47bc7558-48e8-4381-8ac1-73d69d803b2f`
- **Фон** (зал йоги с панорамой): `de2a2fcc-e700-450e-b128-b86a68f74478`
- **Обложка** (лес/природа): `c48584b0-d682-45f7-a317-0c960aefae48`

Доступны через image processor:
`https://feelyoga-dev.vaibkod.online/i/<uuid>?w=600&h=750&fit=crop&fm=webp`

Если перезагрузить эти файлы через админку → UUID-ы поменяются → надо будет править HTML.

## Какие шрифты используются

| Вариант | Heading | Body |
|---|---|---|
| 0 (Orbita) | Manrope 200/300 | Manrope 300 |
| 1 (Serif) | Cormorant Garamond 300/400 italic | Inter 300/400 |
| 2 (Sans) | Onest 300/600 | Onest 300 |

Все через Google Fonts (CDN).

## Палитры

| Вариант | Фон | Текст | Акцент |
|---|---|---|---|
| 0 | `#ffffff` | `#2a2a2a` | `#6b8e6b` (шалфей) |
| 1 | `#fafaf8` | `#1a1a1a` | `#6b7d5f` (оливковый) |
| 2 | `#ffffff` + `#f4f3f0` blocks | `#0e0e0c` | `#2a3d2a` (тёмно-зелёный) |

## После согласования

Когда Михаил выберет один вариант:
1. Переносим выбранную типографику + палитру + структуру блоков в Orbita через override SCSS + кастомизацию `app.vue` / `pages/index.vue`
2. HTML-моки можно либо удалить, либо оставить как референс
3. `vaibkod.online` либо сносим из Caddy + nginx-proxy, либо переиспользуем под другой проект
