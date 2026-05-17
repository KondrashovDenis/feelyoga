<template>
  <div class="category-page">
    <FeelHero :page="heroPage" variant="simple" />

    <section class="feel-section">
      <div class="feel-section__inner">
        <div v-if="topics.length" class="feel-grid">
          <FeelCard v-for="t in topics" :key="t.id" :topic="t" />
        </div>
        <div v-else class="feel-empty">В этой рубрике пока пусто.</div>

        <div v-if="hasMore" class="text-center mt-5">
          <button class="feel-load-more" :disabled="loadingMore" @click="loadMore">
            <span v-if="!loadingMore">Загрузить ещё</span>
            <BSpinner v-else small />
          </button>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
const route = useRoute()
const categoryUri = computed(() => route.params.topics as string)

// получаем категории и находим текущую
const {data: catData} = await useCustomFetch('web/categories').catch(() => ({data: ref({rows: []})}))
const category = computed<any>(() =>
  (catData?.value as any)?.rows?.find((c: any) => c.uri === categoryUri.value)
)

if (!category.value) {
  showError({statusCode: 404, statusMessage: 'Категория не найдена'})
}

// Hero: title = category.title, body = category.description (если есть)
const heroPage = computed(() => ({
  title: category.value?.title || '',
  content: {
    blocks: [
      {id: 'h1', type: 'header', data: {text: category.value?.title || '', level: 1}},
      ...(category.value?.description
        ? [{id: 'desc', type: 'paragraph', data: {text: category.value.description}}]
        : []),
    ],
  },
}))

// Топики этой категории
const limit = 12
const page = ref(1)
const topics = ref<any[]>([])
const total = ref(0)
const loadingMore = ref(false)

const {data: topicsData} = await useCustomFetch(
  `web/topics?category=${encodeURIComponent(categoryUri.value)}&page=1&limit=${limit}&sort=date`
).catch(() => ({data: ref({rows: [], total: 0})}))
topics.value = ((topicsData?.value as any)?.rows || []) as any[]
total.value = ((topicsData?.value as any)?.total || 0) as number

const hasMore = computed(() => topics.value.length < total.value)

async function loadMore() {
  loadingMore.value = true
  page.value++
  try {
    const r: any = await useGet(
      `web/topics?category=${encodeURIComponent(categoryUri.value)}&page=${page.value}&limit=${limit}&sort=date`
    )
    topics.value.push(...(r?.rows || []))
  } finally {
    loadingMore.value = false
  }
}

useSeoMeta({
  title: () => category.value?.title,
})
</script>

<style lang="scss" scoped>
.category-page { background: var(--bs-body-bg); min-height: 60vh; }

.feel-section {
  padding: 60px 0 100px;
}
.feel-section__inner {
  max-width: 1320px;
  margin: 0 auto;
  padding: 0 48px;
}
.feel-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 40px;
}
.feel-empty {
  font-family: 'Inter', sans-serif;
  color: rgba(0,0,0,0.5);
  padding: 60px 0;
  text-align: center;
}
.feel-load-more {
  padding: 14px 32px;
  background: transparent;
  border: 1px solid var(--bs-body-color);
  font-family: 'Inter', sans-serif;
  font-size: 0.82rem;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  transition: all 0.2s;
  cursor: pointer;
  color: var(--bs-body-color);

  &:hover:not(:disabled) {
    background: var(--bs-body-color);
    color: var(--bs-body-bg);
  }
  &:disabled { opacity: 0.5; cursor: wait; }
}

@media (max-width: 900px) {
  .feel-section__inner { padding: 0 20px; }
  .feel-grid { grid-template-columns: 1fr; gap: 32px; }
}
</style>
