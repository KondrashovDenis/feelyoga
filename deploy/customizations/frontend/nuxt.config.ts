// https://nuxt.com/docs/api/configuration/nuxt-config
//
// OVERLAY: копия upstream nuxt.config.ts + добавлены runtimeConfig.public.SENTRY_*
// чтобы plugins/sentry.client.ts читал DSN через useRuntimeConfig.
// При апгрейде upstream — diff/merge вручную, основная правка в блоке runtimeConfig.

import type {NuxtConfig} from '@nuxt/schema'

// OVERLAY: only Russian. Hardcoded — env LOCALES почему-то не подхватывалась
// в build на CI runner. Аудитория Михаила русскоязычная, переключатель не нужен,
// chunks для en/de не должны собираться (экономия диска + чистый footer).
const locales = [
  {code: 'ru', name: 'Русский', file: 'ru.js', language: 'ru-RU'},
]

const config: NuxtConfig = {
  telemetry: false,
  srcDir: 'src/',
  css: ['~/assets/scss/index.scss'],
  devtools: {enabled: false},
  vite: {
    server: {
      allowedHosts: true,
    },
    css: {
      preprocessorOptions: {
        scss: {
          additionalData: '@use "@/assets/scss/_variables.scss" as *;',
          quietDeps: true,
        },
      },
    },
  },
  experimental: {
    appManifest: false,
    normalizeComponentNames: false,
  },
  nitro: {
    experimental: {websocket: true},
    storage: {cache: {driver: 'redis', host: 'redis'}},
    devStorage: {cache: {driver: 'redis', host: 'redis'}},
  },
  routeRules: {
    // @ts-ignore
    '/admin/**': {ssr: false},
    // @ts-ignore
    '/user/**': {ssr: false},
    // @ts-ignore
    '/search': {ssr: false},
  },
  runtimeConfig: {
    CACHE_PAGES_TIME: process.env.CACHE_PAGES_TIME,
    SOCKET_SECRET: process.env.SOCKET_SECRET,
    YANDEX_METRIKA_ID: process.env.YANDEX_METRIKA_ID,
    locales,
    public: {
      TZ: process.env.TZ || 'Europe/Moscow',
      SITE_URL: process.env.SITE_URL || 'http://127.0.0.1:8080/',
      API_URL: process.env.API_URL || '/api/',
      JWT_EXPIRE: process.env.JWT_EXPIRE || '2592000',
      // --- overlay-добавки: Sentry/GlitchTip (см. plugins/sentry.client.ts) ---
      SENTRY_DSN: process.env.NUXT_PUBLIC_SENTRY_DSN || '',
      SENTRY_ENVIRONMENT: process.env.NUXT_PUBLIC_SENTRY_ENVIRONMENT || process.env.SENTRY_ENVIRONMENT || 'production',
      SENTRY_RELEASE: process.env.NUXT_PUBLIC_SENTRY_RELEASE || '',
      // --- Yandex SmartCaptcha (см. components/feel/YandexCaptcha.vue) ---
      YANDEX_CAPTCHA_SITE_KEY: process.env.NUXT_PUBLIC_YANDEX_CAPTCHA_SITE_KEY || '',
      // --- Маркер свежей сборки для CI healthcheck + Sentry release tracking ---
      // SHA коммита запекается в HTML bundle; CI healthcheck делает curl + grep SHA
      // чтобы убедиться что задеплоилась именно ОЖИДАЕМАЯ версия (а не старая
      // работающая по ошибке). Также экспортится как SENTRY_RELEASE.
      DEPLOY_SHA: process.env.NUXT_PUBLIC_DEPLOY_SHA || '',
    },
  },
  app: {
    pageTransition: {name: 'page', mode: 'out-in'},
    layoutTransition: {name: 'page', mode: 'out-in'},
    head: {
      title: process.env.SITE_NAME,
      viewport: 'width=device-width, initial-scale=1, maximum-scale=1, minimum-scale=1, user-scalable=0',
      meta: [
        {name: 'msapplication-config', content: '/favicons/browserconfig.xml'},
        {name: 'theme-color', content: '#fff'},
      ],
      link: [
        {rel: 'apple-touch-icon', sizes: '180x180', href: '/favicons/apple-touch-icon.png'},
        {rel: 'icon', sizes: '32x32', href: '/favicons/favicon-32x32.png', type: 'image/png'},
        {rel: 'icon', sizes: '16x16', href: '/favicons/favicon-16x16.png', type: 'image/png'},
        {rel: 'manifest', href: '/favicons/site.webmanifest'},
        {rel: 'mask-icon', href: '/favicons/safari-pinned-tab.svg'},
        {rel: 'shortcut icon', href: '/favicons/favicon.ico'},
        {rel: 'alternate', type: 'application/rss+xml', title: 'RSS', href: '/rss.xml'},
        {rel: 'alternate', type: 'application/atom+xml', title: 'Atom', href: '/atom.xml'},
      ],
    },
  },
  modules: ['@vesp/frontend'],
  vesp: {
    // @vesp/frontend сам installModule('@nuxtjs/i18n', vesp.i18n) — нужно передать локали ЗДЕСЬ,
    // а не в top-level `i18n:` блоке (там Nuxt i18n не успеет переопределить vesp-defaults).
    // По дефолту vesp: {defaultLocale: 'en', strategy: 'no_prefix', autoscan locales} — даёт 3 локали из lexicons/*.
    i18n: {
      strategy: 'no_prefix',
      defaultLocale: locales[0].code,
      langDir: 'lexicons',
      locales,
      compilation: {strictMessage: false},
      detectBrowserLanguage: false,
    },
    icons: {
      solid: [
        'user', 'power-off', 'globe', 'filter', 'pause', 'play', 'upload', 'question', 'image', 'video', 'file',
        'music', 'code', 'calendar', 'cloud-arrow-down', 'comment', 'comments', 'bars', 'right-to-bracket', 'hashtag',
        'reply', 'trash', 'undo', 'paper-plane', 'wallet', 'hourglass-half', 'lock', 'lock-open', 'heading', 'list',
        'face-smile', 'tags', 'external-link', 'magnifying-glass', 'arrow-up-wide-short', 'arrow-down-short-wide',
        'arrow-up', 'arrow-down', 'download', 'sun', 'moon',
      ],
      regular: ['face-smile'],
    },
  },
  i18n: {
    langDir: 'lexicons',
    // @ts-ignore
    defaultLocale: locales[0].code,
    detectBrowserLanguage: {
      // @ts-ignore
      fallbackLocale: locales[0].code,
    },
    locales,
  },
  compatibilityDate: '2025-07-24',
}

if (process.env.NODE_ENV === 'development') {
  config.modules?.push('@nuxt/eslint', '@nuxtjs/stylelint-module')
  // @ts-ignore
  config.eslint = {
    checker: true,
    config: {
      stylistic: {
        semi: false,
        arrowParens: true,
        quotes: 'single',
        commaDangle: 'always-multiline',
        braceStyle: '1tbs',
        blockSpacing: false,
      },
    },
  }
  // @ts-ignore
  config.stylelint = {
    lintOnStart: false,
  }
}

if (process.env.YANDEX_METRIKA_ID && Number(process.env.YANDEX_METRIKA_ID) > 0) {
  let options = {}
  if (process.env.YANDEX_METRIKA_OPTIONS) {
    try {
      options = JSON.parse(process.env.YANDEX_METRIKA_OPTIONS)
    } catch (e) {}
  }
  config.modules?.push(['yandex-metrika-module-nuxt3', {...options, id: process.env.YANDEX_METRIKA_ID}])
}

export default config
