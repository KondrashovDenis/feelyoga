// Sentry/GlitchTip — client-side error tracking.
// Только в браузере; PII выключен (ФЗ-152 — не отправляем IP, user agent с user_id и т.п.).
// DSN — из NUXT_PUBLIC_SENTRY_DSN (.env на VPS).

import * as Sentry from '@sentry/browser'

export default defineNuxtPlugin((nuxtApp) => {
  const config = useRuntimeConfig().public
  const dsn = (config.SENTRY_DSN as string) || ''
  if (!dsn) return

  Sentry.init({
    dsn,
    environment: (config.SENTRY_ENVIRONMENT as string) || 'production',
    release: (config.SENTRY_RELEASE as string) || undefined,
    sendDefaultPii: false,
    sampleRate: 1.0,
    tracesSampleRate: 0,
    integrations: [],
    beforeSend(event) {
      if (event.request?.url) {
        event.request.url = event.request.url.split('?')[0]
        delete event.request.query_string
        delete event.request.cookies
        delete event.request.headers
      }
      if (event.user) delete event.user
      return event
    },
  })

  // Vue errors — Nuxt hookuet uppermost handler
  nuxtApp.vueApp.config.errorHandler = (err, _instance, info) => {
    Sentry.captureException(err, {extra: {nuxtInfo: info}})
  }
  nuxtApp.hook('vue:error', (err) => {
    Sentry.captureException(err)
  })
})
