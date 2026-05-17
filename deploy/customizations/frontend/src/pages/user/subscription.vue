<template>
  <div>
    <FeelHero :page="heroPage" variant="simple" />

    <section class="feel-section">
      <div class="feel-section__inner">
        <BRow v-if="user?.subscription" class="d-flex mb-5 row-gap-4">
          <BCol md="4">
            <div class="fw-bold">
              {{ t('components.payment.subscription.level.current') }}
            </div>
            <div>{{ currentLevel?.title }}</div>
          </BCol>
          <BCol md="4">
            <div class="fw-bold">
              {{ t('components.payment.subscription.paid_until') }}
            </div>
            <div>{{ paid }}</div>
          </BCol>
          <BCol v-if="nextLevel" md="4">
            <div class="fw-bold">
              {{ t('components.payment.subscription.level.new') }}
            </div>
            <div>{{ nextLevel.title }}</div>
          </BCol>
        </BRow>

        <div v-if="$levels.length">
          <h4 v-if="user?.subscription" class="pt-4 border-bottom feel-h4">
            {{ t('widgets.levels') }}
          </h4>
          <WidgetsLevels user-page />
        </div>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
const {t} = useI18n()
const {user} = useAuth()
const {$levels} = useNuxtApp()

const heroPage = {
  title: 'Подписка',
  content: {
    blocks: [
      {id: 'h1', type: 'header', data: {text: 'Подписка', level: 1}},
      {id: 'desc', type: 'paragraph', data: {text: 'Управление подпиской на видеотеку Михаила.'}},
    ],
  },
}

const currentLevel = computed(() => {
  return $levels.value.find((i: VespLevel) => i.id === user.value?.subscription?.level_id)
})
const nextLevel = computed(() => {
  return user.value?.subscription?.next_level_id
    ? $levels.value.find((i: VespLevel) => i.id === user.value?.subscription?.next_level_id)
    : undefined
})
const paid = computed(() => {
  return formatDate(user.value?.subscription?.active_until)
})
</script>

<style lang="scss" scoped>
.feel-section { padding: 40px 0 100px; }
.feel-section__inner {
  max-width: 1100px;
  margin: 0 auto;
  padding: 0 48px;
}
.feel-h4 {
  font-family: 'Cormorant Garamond', Georgia, serif;
  font-weight: 400;
  font-size: 1.8rem;
  margin: 2em 0 1em;
}
@media (max-width: 900px) {
  .feel-section__inner { padding: 0 20px; }
}
</style>
