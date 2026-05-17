<template>
  <BNavbar id="navbar" sticky="top" :container="false">
    <BContainer>
      <BNavbarBrand :to="{name: 'index'}" class="p-0 brand-text" @click="hideSidebar">
        filippov.yoga
      </BNavbarBrand>

      <BNav class="d-none d-md-flex feel-nav ms-4">
        <!-- Категории — выпадающее меню "Практики" -->
        <BNavItemDropdown v-if="categories.length" class="feel-nav__dropdown">
          <template #button-content>
            <span>Практики</span>
          </template>
          <BDropdownItem
            v-for="cat in categories"
            :key="cat.id"
            :to="{name: 'topics', params: {topics: cat.uri}}"
          >
            {{ cat.title }}
          </BDropdownItem>
        </BNavItemDropdown>

        <!-- Якоря на главной -->
        <BNavItem :to="{name: 'index', hash: '#about'}">Обо мне</BNavItem>
        <BNavItem :to="{name: 'index', hash: '#subscription'}">Подписка</BNavItem>

        <!-- Кастомные страницы из admin (position=header или both, кроме home-hero/sub-intro/about) -->
        <template v-for="page in extraPages" :key="page.id">
          <a v-if="page.external" :href="page.link" :target="page.blank ? '_blank' : '_self'" class="nav-link">
            {{ page.name }}&nbsp;<sup><VespFa icon="external-link" size="sm" /></sup>
          </a>
          <BNavItem v-else :to="{name: 'pages-alias', params: {alias: page.alias}}">
            {{ page.name }}
          </BNavItem>
        </template>
      </BNav>

      <BNavbarNav class="ms-auto">
        <BButton variant="light" class="me-1" @click="() => changeColorTheme()">
          <VespFa :key="colorIcon[1]" :icon="colorIcon" fixed-width />
        </BButton>
        <AppLogin :btn-variant="btnVariant" @click="hideSidebar">
          <template #user-menu>
            <BDropdownItem v-if="hasAdmin" :to="{name: 'admin'}" link-class="border-bottom">
              {{ $t('pages.admin.title') }}
            </BDropdownItem>
            <BDropdownItem :to="{name: 'user-profile'}">
              {{ $t('pages.user.profile') }}
            </BDropdownItem>
            <BDropdownItem v-if="$levels.length" :to="{name: 'user-subscription'}">
              {{ $t('pages.user.subscription') }}
            </BDropdownItem>
            <BDropdownItem :to="{name: 'user-payments'}">
              {{ $t('pages.user.payments') }}
            </BDropdownItem>
          </template>
        </AppLogin>
        <BButton v-if="sidebar" :variant="btnVariant" class="d-md-none ms-1" @click.stop="toggleSidebar">
          <Transition name="fade" mode="out-in">
            <VespFa v-if="!$sidebar" icon="bars" class="fa-fw" />
            <VespFa v-else icon="times" class="fa-fw" />
          </Transition>
        </BButton>
      </BNavbarNav>
    </BContainer>
  </BNavbar>
</template>

<script setup lang="ts">
import type {BaseButtonVariant} from 'bootstrap-vue-next'
import {type BasicColorSchema, useColorMode} from '@vueuse/core'

defineProps({
  sidebar: {
    type: Boolean,
    default: false,
  },
  btnVariant: {
    type: String as PropType<keyof BaseButtonVariant>,
    default: 'light',
  },
})

const hasAdmin = computed(() => getAdminSections().length)
const {loggedIn} = useAuth()
const {$sidebar, $variables, $levels, $pages} = useNuxtApp()
const {system, store} = useColorMode({attribute: 'data-bs-theme', selector: 'body'})
const saved = useCookie<BasicColorSchema | undefined>('colorMode', {maxAge: $variables.value.JWT_EXPIRE})
const colorIcon = computed(() => {
  return ['fas', store.value === 'dark' ? 'moon' : 'sun']
})

// Категории для выпадающего "Практики"
const {data: catData} = await useCustomFetch('web/categories').catch(() => ({data: ref({rows: []})}))
const categories = computed<any[]>(() => (catData?.value as any)?.rows?.filter((c: any) => c.active) || [])

// Прочие страницы из админки (position=header/both), кроме наших скрытых из landing
const HIDDEN_ALIASES = ['home-hero', 'subscription-intro', 'about']
const extraPages = computed(() => {
  return $pages.value.filter((p: any) =>
    ['header', 'both'].includes(p.position) && !HIDDEN_ALIASES.includes(p.alias)
  )
})

function toggleSidebar() {
  $sidebar.value = !$sidebar.value
}

function hideSidebar() {
  $sidebar.value = false
}

function changeColorTheme(newValue: BasicColorSchema | undefined = undefined) {
  if (newValue) {
    store.value = newValue
  } else {
    store.value = store.value === 'light' ? 'dark' : 'light'
  }
  saved.value = store.value
}
</script>

<style lang="scss" scoped>
.brand-text {
  font-family: 'Cormorant Garamond', Georgia, serif;
  font-weight: 400;
  font-style: italic;
  font-size: 1.7rem;
  letter-spacing: 0.02em;
  color: var(--bs-body-color);

  &:hover {
    color: var(--bs-primary);
    text-decoration: none;
  }
}

.feel-nav {
  gap: 4px;

  :deep(.nav-link) {
    font-family: 'Inter', sans-serif;
    font-size: 0.92rem;
    font-weight: 400;
    color: var(--bs-body-color);
    opacity: 0.75;
    padding: 8px 16px;
    transition: opacity 0.2s;

    &:hover,
    &.router-link-active {
      opacity: 1;
      color: var(--bs-body-color);
    }
  }
}
</style>
