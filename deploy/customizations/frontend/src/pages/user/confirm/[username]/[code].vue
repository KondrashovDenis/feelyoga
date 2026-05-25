<template>
  <div class="p-5 text-center">
    <BSpinner v-if="loading" size="lg" />
    <div v-else-if="alreadyActive" class="mx-auto" style="max-width:520px">
      <h2 class="mb-3" style="font-family:'Cormorant Garamond',Georgia,serif;font-weight:300">
        Аккаунт уже активирован
      </h2>
      <p class="text-muted mb-4">
        Ссылка из приветственного письма одноразовая и срабатывает только при первом клике.
        Похоже, активация уже была пройдена — войдите по логину и паролю.
      </p>
      <NuxtLink to="/" class="btn btn-primary">На главную</NuxtLink>
    </div>
  </div>
</template>

<script setup lang="ts">
/**
 * OVERLAY upstream pages/user/confirm/[username]/[code].vue
 * Изменено: 404 от /api/security/activate (повторный клик по welcome-ссылке,
 * reset_password уже сброшен в null после успешной активации) обрабатывается
 * без Nuxt error page — показываем дружелюбный экран «Аккаунт уже активен».
 * Также пропускаем error в Sentry с пометкой handled — не спамит Telegram alerts.
 */
const {params} = useRoute()
const loading = ref(true)
const alreadyActive = ref(false)
const route = ref<{name: string}>({name: 'index'})

if (params.username && params.code) {
  try {
    const {token} = await usePost('security/activate', params)
    if (token) {
      await useAuth().setToken(token)
      route.value = {name: 'user-profile'}
    }
  } catch (e: any) {
    // 404 = пользователь уже активирован (reset_password=null после первого успеха)
    if (e?.statusCode === 404 || e?.response?.status === 404) {
      alreadyActive.value = true
      loading.value = false
      // На главную не редиректим — пусть юзер сам кликнет «Войти» либо «На главную»
      return
    }
    // Другие ошибки — стандартное поведение Nuxt
    throw e
  }
}

onMounted(() => {
  if (!alreadyActive.value) {
    navigateTo(route.value, {replace: true, redirectCode: 302})
  }
})
</script>
