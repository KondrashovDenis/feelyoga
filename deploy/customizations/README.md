# Кастомизации FeelYoga поверх Orbita

Папка-overlay над `~/projects/feelyoga/frontend/src/` на debianOCR.
При деплое (или после `git pull` upstream Orbita) копировать содержимое
`frontend/` поверх соответствующей структуры в Orbita.

## Применение

```bash
# на debianOCR
cd ~/projects/feelyoga
cp -r ~/<feelyoga-repo>/deploy/customizations/frontend/. ./
docker compose restart node       # Nuxt rebuild (~1-3 мин)
```

## Какие файлы переопределены

### `frontend/src/components/app/navbar.vue`
- BImg-логотип `public/project/logo.svg` заменён на текст `filippov.yoga`
- Шрифт Manrope, font-weight: 200, font-size: 1.5rem

### `frontend/src/components/app/footer.vue`
- Удалена правая колонка с `<a href="github.com/bezumkin/orbita">made_with</a>`
- Дефолт copyright (когда `$settings.copyright` пусто): `Разработка сайта vaibkod.ru`
- Левая колонка с copyright теперь `md=6`, центральная (links + lang) `md=6`

### `frontend/src/components/widgets/author.vue`
- Заголовок виджета хардкодом `filippov.yoga` вместо `$settings.title`
- Шрифт Manrope, font-weight: 200, font-size: 1.75rem
- Виджет всегда показывается (раньше требовал `$settings.poster || $settings.description`)

### `frontend/src/app.vue`
- Главная (route name === 'index') рендерится **full-width**, без BContainer / BCol — наши секции сами центрируются
- Остальные страницы — `BContainer` с `BCol lg=12 mx-auto` (правая колонка с виджетами скрыта целиком потому что в `.env` `HIDE_WIDGETS=author,search,online,levels,categories,tags,pages`)

### `frontend/src/pages/index.vue` (наш landing)
- Hero (FeelHero) — берёт текст из `pages/home-hero` Orbita, портрет из `$settings.poster`
- Practices grid — `web/topics?limit=9&sort=date` через FeelCard
- About — `pages/about` (rich-text в EditorJS)
- Pricing — `web/levels` + intro из `pages/subscription-intro`

### `frontend/src/components/feel/Hero.vue` + `Card.vue` — новые компоненты
- `FeelHero` — universal с props `page`, `portraitImage`, `cta`, `variant` ('full' | 'simple')
- `FeelCard` — editorial-карточка топика 4:5

### `frontend/src/components/app/navbar.vue`
- `@import` Google Fonts Manrope (200/300/400/500/600/700)
- `$font-family-sans-serif: 'Manrope', ...`
- `$headings-font-weight: 300`, `$font-weight-base: 300`
- `$body-color: #2a2a2a`, `$body-bg: #ffffff`
- `$primary: #6b8e6b` (тёмный шалфей)
- `$link-color: $primary`

## Что **не** включено в overlay (через админку)

- `$settings.title` — название сайта (`<title>`, `og:title`). Менять через `/admin → Settings`.
- `$settings.description` — описание (meta description). Через `/admin → Settings`.
- `$settings.copyright` — если задать, переопределит наш дефолт vaibkod.ru.
- `$settings.poster` — фото автора в виджете author.
- `$settings.background` — фон main-background сверху.

## Бэкапы оригиналов

При первой правке на debianOCR сделаны бэкапы:
- `frontend/src/components/app/navbar.vue.orig`
- `frontend/src/components/app/footer.vue.orig`
- `frontend/src/components/widgets/author.vue.orig`
- `frontend/src/assets/scss/_variables.scss.orig`
