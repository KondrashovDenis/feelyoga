<template>
  <footer id="footer" class="mt-5 py-4">
    <BContainer class="text-muted small">
      <BRow align-v="start">
        <BCol md="6" class="text-center text-md-start mb-3 mb-md-0">
          <div class="fw-semibold mb-2">
            {{ owner }} &copy; {{ Array.isArray(date) ? date.join(' &mdash; ') : date }}
          </div>
          <!-- Legal-ссылки ФЗ-152 — обязательны на каждой странице -->
          <nav class="legal-links">
            <NuxtLink to="/pages/privacy" class="legal-links__item">Политика конфиденциальности</NuxtLink>
            <NuxtLink to="/pages/offer" class="legal-links__item">Публичная оферта</NuxtLink>
            <NuxtLink to="/pages/refund" class="legal-links__item">Политика возврата</NuxtLink>
            <NuxtLink to="/pages/cookies" class="legal-links__item">Cookies</NuxtLink>
          </nav>
        </BCol>
        <BCol md="6" :class="middleClasses">
          <AppPages position="footer" />
          <AppLanguage v-if="locales.length > 1" />
        </BCol>
      </BRow>
    </BContainer>
  </footer>
</template>

<script setup lang="ts">
const {locale, locales} = useI18n()
const {$settings} = useNuxtApp()

const date = computed(() => {
  const year = new Date().getFullYear()
  const started = $settings.value.started as string
  if (started) {
    const tmp = new Date(started).getFullYear()
    if (tmp !== year) {
      return [tmp, year]
    }
  }
  return year
})
const owner = computed(() => {
  const owner = $settings.value.copyright
  if (owner) {
    return owner
  }
  return locale.value === 'ru'
    ? 'Разработка сайта vaibkod.ru'
    : 'Made by vaibkod.ru'
})
const middleClasses = [
  'my-2',
  'my-md-0',
  'd-flex',
  'flex-column',
  'flex-md-row',
  'align-items-center',
  'justify-content-center',
  'justify-content-md-between',
]

if (!locales.value.filter((i) => i.code === locale.value).length) {
  locale.value = locales.value[0].code
}
</script>

<style scoped>
.legal-links {
  display: flex;
  flex-wrap: wrap;
  gap: 4px 16px;
  font-size: 0.78rem;
  line-height: 1.6;
  justify-content: center;
}
@media (min-width: 768px) {
  .legal-links {
    justify-content: flex-start;
  }
}
.legal-links__item {
  color: rgba(0, 0, 0, 0.55);
  text-decoration: none;
  border-bottom: 1px solid transparent;
  transition: color 0.2s, border-color 0.2s;
}
.legal-links__item:hover {
  color: var(--bs-primary, #6b7d5f);
  border-bottom-color: currentColor;
  text-decoration: none;
}
[data-bs-theme='dark'] .legal-links__item {
  color: rgba(255, 255, 255, 0.55);
}
</style>
