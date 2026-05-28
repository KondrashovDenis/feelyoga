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
 * 404 от /api/security/activate (повторный клик по welcome-ссылке, reset_password
 * уже сброшен в null после первой активации) обрабатываем без Nuxt error page —
 * показываем дружелюбный экран «Аккаунт уже активирован».
 *
 * BUG-RESOLVED: предыдущая версия имела `return` на top-level <script setup>,
 * Vue compiler ругался "'return' outside of function" — нельзя ранний return
 * в module-scope. Логика переделана через guard-флаг shouldRedirect.
 */
const {params} = useRoute()
const loading = ref(true)
const alreadyActive = ref(false)
const shouldRedirect = ref(false)
const redirectTarget = ref<{name: string}>({name: 'index'})

if (params.username && params.code) {
  try {
    const {token} = await usePost('security/activate', params)
    if (token) {
      await useAuth().setToken(token)
      redirectTarget.value = {name: 'user-profile'}
      shouldRedirect.value = true
    }
  } catch (e: any) {
    // 404 = пользователь уже активирован (reset_password=null после первого успеха)
    const status = e?.statusCode ?? e?.response?.status
    if (status === 404) {
      alreadyActive.value = true
      loading.value = false
      // shouldRedirect остаётся false — onMounted редирект не сделает
    } else {
      // Другие ошибки — стандартное поведение Nuxt
      throw e
    }
  }
}

// onMounted редиректит ТОЛЬКО при успешной активации.
// Если попали в alreadyActive (404) — остаёмся на странице с дружелюбным сообщением.
onMounted(() => {
  if (shouldRedirect.value) {
    navigateTo(redirectTarget.value, {replace: true, redirectCode: 302})
  }
})
</script>
