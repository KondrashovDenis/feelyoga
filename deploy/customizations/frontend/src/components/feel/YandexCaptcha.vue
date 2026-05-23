<template>
  <div v-if="siteKey" ref="containerRef" class="my-3" />
</template>

<script setup lang="ts">
/**
 * Yandex SmartCaptcha — Vue 3 компонент-обёртка.
 *
 * Использование:
 *   const captchaToken = ref('')
 *   const captchaRef = ref()
 *   <YandexCaptcha v-model="captchaToken" ref="captchaRef" />
 *   // после submit (success или fail) — captchaRef.value?.reset() чтобы получить новый токен
 *
 * Если NUXT_PUBLIC_YANDEX_CAPTCHA_SITE_KEY пуст — компонент не рендерится,
 * v-model сразу = '' (dev mode без капчи; backend пропустит если SECRET тоже пуст).
 *
 * Invisible mode по умолчанию: пользователь капчу не видит,
 * при подозрении на бота — pop-up с челленджем.
 *
 * API: https://yandex.cloud/ru/docs/smartcaptcha/concepts/widget-methods
 */

interface SmartCaptchaWidget {
  render: (
    container: HTMLElement | string,
    options: {
      sitekey: string
      callback?: (token: string) => void
      'error-callback'?: () => void
      'expired-callback'?: () => void
      invisible?: boolean
      hideShield?: boolean
      shieldPosition?: string
    },
  ) => number
  reset: (widgetId?: number) => void
  execute: (widgetId?: number) => void
  destroy: (widgetId?: number) => void
}

declare global {
  interface Window {
    smartCaptcha?: SmartCaptchaWidget
  }
}

const SCRIPT_SRC = 'https://smartcaptcha.yandexcloud.net/captcha.js'

const props = withDefaults(
  defineProps<{
    modelValue: string
    invisible?: boolean
    hideShield?: boolean
  }>(),
  {invisible: true, hideShield: false},
)
const emit = defineEmits<{(e: 'update:modelValue', token: string): void}>()

const runtime = useRuntimeConfig().public
const siteKey = (runtime.YANDEX_CAPTCHA_SITE_KEY as string) || ''

const containerRef = ref<HTMLElement | null>(null)
const widgetId = ref<number | null>(null)

let scriptPromise: Promise<void> | null = null
function loadScript(): Promise<void> {
  if (window.smartCaptcha) return Promise.resolve()
  if (scriptPromise) return scriptPromise
  scriptPromise = new Promise((resolve, reject) => {
    const existing = document.querySelector<HTMLScriptElement>(`script[src^="${SCRIPT_SRC}"]`)
    if (existing && window.smartCaptcha) {
      resolve()
      return
    }
    const s = document.createElement('script')
    s.src = SCRIPT_SRC
    s.async = true
    s.defer = true
    s.onload = () => resolve()
    s.onerror = () => reject(new Error('SmartCaptcha script failed to load'))
    document.head.appendChild(s)
  })
  return scriptPromise
}

function reset() {
  if (window.smartCaptcha && widgetId.value !== null) {
    window.smartCaptcha.reset(widgetId.value)
    if (props.invisible) {
      window.smartCaptcha.execute(widgetId.value)
    }
  }
}
defineExpose({reset})

onMounted(() => {
  if (!siteKey) {
    emit('update:modelValue', '')
    return
  }
  loadScript()
    .then(() => {
      if (!containerRef.value || !window.smartCaptcha) return
      widgetId.value = window.smartCaptcha.render(containerRef.value, {
        sitekey: siteKey,
        callback: (token: string) => emit('update:modelValue', token),
        'error-callback': () => emit('update:modelValue', ''),
        'expired-callback': () => emit('update:modelValue', ''),
        invisible: props.invisible,
        hideShield: props.hideShield,
      })
      if (props.invisible && widgetId.value !== null) {
        window.smartCaptcha.execute(widgetId.value)
      }
    })
    .catch((err) => console.error('[SmartCaptcha]', err))
})

onUnmounted(() => {
  if (window.smartCaptcha && widgetId.value !== null) {
    window.smartCaptcha.destroy(widgetId.value)
    widgetId.value = null
  }
})
</script>
