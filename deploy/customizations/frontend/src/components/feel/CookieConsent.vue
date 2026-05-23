<template>
  <Teleport to="body">
    <Transition name="fade">
      <div v-if="show" class="cc-banner" role="dialog" aria-label="Cookie consent">
        <div class="cc-banner__title">Файлы cookie</div>
        <div class="cc-banner__text">
          Мы используем cookies для корректной работы сайта. Продолжая, вы соглашаетесь с
          <NuxtLink to="/pages/privacy" class="cc-link">Политикой обработки персональных данных</NuxtLink>
          и
          <NuxtLink to="/pages/cookies" class="cc-link">Политикой использования cookies</NuxtLink>.
        </div>
        <div class="cc-banner__actions">
          <button type="button" class="cc-btn cc-btn--primary" @click="acceptAll">
            Принять все
          </button>
          <button type="button" class="cc-btn cc-btn--secondary" @click="openSettings = true">
            Настроить
          </button>
        </div>
      </div>
    </Transition>

    <Transition name="fade">
      <div
        v-if="openSettings"
        class="cc-modal-bg"
        role="dialog"
        aria-modal="true"
        aria-label="Cookie settings"
        @click.self="openSettings = false"
      >
        <div class="cc-modal">
          <h3 class="cc-modal__title">Настройки cookies</h3>
          <p class="cc-modal__lead">
            Файлы cookies, необходимые для корректной работы сайта, всегда включены.
            Остальные категории можно настроить.
          </p>

          <div class="cc-cat cc-cat--required">
            <div class="cc-cat__head">
              <div class="cc-cat__name">Необходимые cookies</div>
              <span class="cc-cat__pill">Всегда включены</span>
            </div>
            <p class="cc-cat__desc">
              Без этих cookies сайт не работает: хранение сессии, защита форм,
              сохранение настроек интерфейса.
            </p>
          </div>

          <div class="cc-cat">
            <div class="cc-cat__head">
              <div class="cc-cat__name">Аналитические cookies</div>
              <label class="cc-toggle">
                <input v-model="analytics" type="checkbox" />
                <span class="cc-toggle__track" :class="{'cc-toggle__track--on': analytics}" />
                <span class="cc-toggle__thumb" :class="{'cc-toggle__thumb--on': analytics}" />
              </label>
            </div>
            <p class="cc-cat__desc">
              Помогают понимать, как используется сайт, чтобы улучшать его работу.
              Обезличенная статистика без идентификации конкретного пользователя.
            </p>
          </div>

          <div class="cc-cat cc-cat--last">
            <div class="cc-cat__head">
              <div class="cc-cat__name">Рекламные cookies</div>
              <label class="cc-toggle">
                <input v-model="advertising" type="checkbox" />
                <span class="cc-toggle__track" :class="{'cc-toggle__track--on': advertising}" />
                <span class="cc-toggle__thumb" :class="{'cc-toggle__thumb--on': advertising}" />
              </label>
            </div>
            <p class="cc-cat__desc">
              На текущий момент на сайте не используются. Пункт зарезервирован.
            </p>
          </div>

          <div class="cc-modal__actions">
            <button type="button" class="cc-btn cc-btn--primary" @click="saveCustom">
              Сохранить выбор
            </button>
            <button type="button" class="cc-btn cc-btn--secondary" @click="acceptAll">
              Принять все
            </button>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
/**
 * Cookie consent banner для Filippov Yoga.
 *
 * Портировано из sochispirit/CookieConsent.tsx (React) на Vue 3 + Nuxt 3.
 * Сохранение в localStorage по ключу fy_cookie_consent_v1 — версионирование
 * через `v: 1`, при изменении политики bump до 2 и баннер появится снова.
 *
 * Категории: essential (всегда on), analytics, advertising.
 * Сейчас analytics/advertising — placeholder'ы (Яндекс.Метрика ещё не подключена),
 * но инфраструктура готова: добавить интеграцию = одна проверка consent.analytics.
 */

interface Consent {
  v: number
  essential: true
  analytics: boolean
  advertising: boolean
  ts: number
}

const STORAGE_KEY = 'fy_cookie_consent_v1'

const show = ref(false)
const openSettings = ref(false)
const analytics = ref(false)
const advertising = ref(false)

onMounted(() => {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (raw) {
      const saved = JSON.parse(raw) as Consent
      if (saved && saved.v === 1) return
    }
  } catch {}
  // показываем с небольшой задержкой, чтобы не флешить при загрузке
  setTimeout(() => {
    show.value = true
  }, 400)
})

function save(state: {analytics: boolean; advertising: boolean}) {
  try {
    localStorage.setItem(
      STORAGE_KEY,
      JSON.stringify({
        v: 1,
        essential: true,
        analytics: state.analytics,
        advertising: state.advertising,
        ts: Date.now(),
      } satisfies Consent),
    )
  } catch {}
  show.value = false
  openSettings.value = false
}

function acceptAll() {
  save({analytics: true, advertising: true})
}

function saveCustom() {
  save({analytics: analytics.value, advertising: advertising.value})
}
</script>

<style scoped>
.cc-banner {
  position: fixed;
  right: 24px;
  bottom: 24px;
  left: auto;
  z-index: 9999;
  max-width: 520px;
  padding: 24px 28px;
  background: #fafaf8;
  border: 1px solid #e8e6df;
  border-radius: 8px;
  box-shadow: 0 12px 40px rgba(0, 0, 0, 0.12);
  font-family: Inter, system-ui, sans-serif;
}
@media (max-width: 640px) {
  .cc-banner {
    right: 12px;
    bottom: 12px;
    left: 12px;
    max-width: none;
    padding: 20px;
  }
}

.cc-banner__title {
  font-family: 'Cormorant Garamond', Georgia, serif;
  font-size: 1.4rem;
  font-weight: 400;
  font-style: italic;
  letter-spacing: 0.02em;
  color: #1a1a1a;
  margin-bottom: 10px;
}
.cc-banner__text {
  font-size: 0.9rem;
  line-height: 1.5;
  color: rgba(0, 0, 0, 0.7);
  margin-bottom: 16px;
}
.cc-banner__actions {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.cc-link {
  color: #6b7d5f;
  text-decoration: underline;
  text-underline-offset: 2px;
}
.cc-link:hover {
  color: #1a1a1a;
}

.cc-btn {
  font-family: Inter, sans-serif;
  font-size: 0.78rem;
  font-weight: 600;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  padding: 12px 22px;
  border: none;
  cursor: pointer;
  transition: all 0.2s;
}
.cc-btn--primary {
  background: #1a1a1a;
  color: #fafaf8;
}
.cc-btn--primary:hover {
  background: #6b7d5f;
}
.cc-btn--secondary {
  background: transparent;
  color: #1a1a1a;
  border: 1.5px solid #c8c5b9;
}
.cc-btn--secondary:hover {
  border-color: #6b7d5f;
  color: #6b7d5f;
}

.cc-modal-bg {
  position: fixed;
  inset: 0;
  z-index: 10000;
  background: rgba(0, 0, 0, 0.55);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
}
.cc-modal {
  background: #fafaf8;
  color: #1a1a1a;
  border-radius: 8px;
  padding: 36px;
  max-width: 540px;
  width: 100%;
  max-height: 90vh;
  overflow-y: auto;
  font-family: Inter, sans-serif;
}
.cc-modal__title {
  font-family: 'Cormorant Garamond', Georgia, serif;
  font-size: 2rem;
  font-weight: 300;
  margin: 0 0 12px;
}
.cc-modal__lead {
  font-size: 0.92rem;
  line-height: 1.55;
  color: rgba(0, 0, 0, 0.65);
  margin-bottom: 20px;
}
.cc-modal__actions {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 24px;
}

.cc-cat {
  padding: 16px 0;
  border-bottom: 1px solid #e8e6df;
}
.cc-cat--last {
  border-bottom: none;
}
.cc-cat__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  margin-bottom: 8px;
}
.cc-cat__name {
  font-weight: 600;
  font-size: 0.95rem;
}
.cc-cat__pill {
  font-size: 0.7rem;
  font-weight: 700;
  letter-spacing: 0.15em;
  text-transform: uppercase;
  color: #6b7d5f;
}
.cc-cat__desc {
  font-size: 0.87rem;
  line-height: 1.5;
  color: rgba(0, 0, 0, 0.62);
  margin: 0;
}

/* Toggle switch */
.cc-toggle {
  position: relative;
  display: inline-block;
  width: 44px;
  height: 24px;
  cursor: pointer;
  flex-shrink: 0;
}
.cc-toggle input {
  position: absolute;
  width: 1px;
  height: 1px;
  opacity: 0;
  overflow: hidden;
}
.cc-toggle__track {
  position: absolute;
  inset: 0;
  border-radius: 12px;
  background: #d4d2c9;
  transition: background 0.2s;
}
.cc-toggle__track--on {
  background: #6b7d5f;
}
.cc-toggle__thumb {
  position: absolute;
  left: 2px;
  top: 2px;
  width: 20px;
  height: 20px;
  background: #fafaf8;
  border-radius: 50%;
  transition: transform 0.2s;
}
.cc-toggle__thumb--on {
  transform: translateX(20px);
}

/* Transition */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.25s;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
