<template>
  <div>
    <NuxtLoadingIndicator color="var(--bs-primary)" />

    <div id="layout" :class="mainClasses">
      <AppNavbar class="border-bottom" :sidebar="!isAdmin" />

      <!-- Главная — full-width, без контейнера, без виджетов; страницы рисуют свой layout -->
      <template v-if="isLanding">
        <main class="flex-grow-1">
          <slot>
            <NuxtPage />
          </slot>
        </main>
      </template>

      <!-- Остальные страницы — центрированный контент, без правой колонки (виджеты глобально скрыты HIDE_WIDGETS) -->
      <template v-else>
        <BContainer class="pt-4 flex-grow-1">
          <BRow>
            <BCol :lg="hasAnyWidget ? 8 : 12" :class="{'mx-auto': !hasAnyWidget}">
              <slot>
                <NuxtPage />
              </slot>
            </BCol>
            <BCol v-if="hasAnyWidget && !$isMobile" lg="4" class="offset">
              <div v-if="!hideWidgets.includes('author')" class="column"><WidgetsAuthor /></div>
              <WidgetsSearch v-if="!hideWidgets.includes('search')" class="column" />
              <WidgetsOnline v-if="!hideWidgets.includes('online')" class="column" />
              <WidgetsLevels v-if="!hideWidgets.includes('levels')" class="column" />
              <WidgetsCategories v-if="!hideWidgets.includes('categories')" class="column" />
              <WidgetsTags v-if="!hideWidgets.includes('tags')" class="column" />
              <WidgetsScrollTop />
            </BCol>
          </BRow>
        </BContainer>
      </template>

      <AppSidebar
        v-if="$isMobile"
        :show-pages="!hideWidgets.includes('pages')"
        :show-author="!hideWidgets.includes('author')"
        :show-search="!hideWidgets.includes('search')"
        :show-online="!hideWidgets.includes('online')"
        :show-levels="!hideWidgets.includes('levels')"
        :show-categories="!hideWidgets.includes('categories')"
        :show-tags="!hideWidgets.includes('tags')"
      />
      <AppFooter class="border-top" />
      <AppPayment />
    </div>
  </div>
</template>

<script setup lang="ts">
const {$settings, $variables, $image, $isMobile} = useNuxtApp()
const router = useRouter()
const route = useRoute()

const isLanding = computed(() => (route.name as string) === 'index')
const isAdmin = computed(() => (route.name as string)?.startsWith('admin'))

const hideWidgets = computed(() => {
  const data = $variables.value?.HIDE_WIDGETS?.split(',').map((i) => i.trim().toLowerCase()) || []
  if ($variables.value?.COMMENTS_SHOW_ONLINE === '0') data.push('online')
  return data
})
// все 7 виджетов: author, search, online, levels, categories, tags, pages
const hasAnyWidget = computed(() => {
  const all = ['author', 'search', 'online', 'levels', 'categories', 'tags']
  return all.some((w) => !hideWidgets.value.includes(w))
})

const mainClasses = computed(() => {
  const arr = ['d-flex', 'flex-column', 'min-vh-100']
  if (isLanding.value) arr.push('landing')
  return arr
})

function handleResize() {
  const width = import.meta.client ? window.innerWidth : 768
  $isMobile.value = width < 768
}
onMounted(() => {
  handleResize()
  window.addEventListener('resize', handleResize)
})
onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
})

useHead(() => ({
  link: [{rel: 'canonical', href: $variables.value.SITE_URL + route.path.slice(1)}],
}))

const description = stripTags(String($settings.value.description))
useSeoMeta({
  title: $settings.value.title as string,
  ogTitle: $settings.value.title as string,
  description,
  ogDescription: description,
  ogImage: $settings.value.poster ? $image($settings.value.poster as VespFile) : undefined,
  twitterCard: 'summary_large_image',
})
</script>
