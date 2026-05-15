<template>
  <BNavbar id="navbar" sticky="top" :container="false">
    <BContainer>
      <BNavbarBrand :to="{name: 'index'}" class="p-0 brand-text" @click="hideSidebar">
        filippov.yoga
      </BNavbarBrand>

      <AppPages class="d-none d-md-flex" />

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
const {$sidebar, $variables, $levels} = useNuxtApp()
const {system, store} = useColorMode({attribute: 'data-bs-theme', selector: 'body'})
const saved = useCookie<BasicColorSchema | undefined>('colorMode', {maxAge: $variables.value.JWT_EXPIRE})
const colorIcon = computed(() => {
  return ['fas', store.value === 'dark' ? 'moon' : 'sun']
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
  font-family: 'Manrope', system-ui, -apple-system, sans-serif;
  font-weight: 200;
  font-size: 1.5rem;
  letter-spacing: 0.02em;
  color: var(--bs-body-color);

  &:hover {
    color: var(--bs-primary);
    text-decoration: none;
  }
}
</style>
