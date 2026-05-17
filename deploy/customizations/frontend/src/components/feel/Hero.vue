<template>
  <section :class="['feel-hero', `feel-hero--${variant}`, {'feel-hero--with-image': portraitImage}]">
    <div class="feel-hero__inner">
      <div class="feel-hero__text">
        <h1 class="feel-hero__title" v-html="title" />
        <div v-if="hasBody" class="feel-hero__lead" @click="$contentClick">
          <EditorContent :content="{blocks: bodyBlocks}" />
        </div>
        <a v-if="cta && cta.href" class="feel-hero__cta" :href="cta.href">
          {{ cta.text || 'Подробнее' }}
        </a>
      </div>
      <div v-if="portraitImage" class="feel-hero__portrait" :style="{backgroundImage: `url('${portraitImage}')`}" />
    </div>
  </section>
</template>

<script setup lang="ts">
interface HeroBlock { id?: string; type: string; data: { text?: string; level?: number } }
interface HeroPage { title?: string; content?: { blocks?: HeroBlock[] } }

const props = defineProps<{
  page?: HeroPage,
  portraitImage?: string,
  cta?: { text?: string; href?: string },
  variant?: 'full' | 'simple',
}>()

const variant = computed(() => props.variant || 'full')
const blocks = computed<HeroBlock[]>(() => props.page?.content?.blocks || [])
const headerIdx = computed(() => blocks.value.findIndex((b) => b.type === 'header' && b.data?.level === 1))
const title = computed(() => {
  if (headerIdx.value > -1) return blocks.value[headerIdx.value].data.text || ''
  return props.page?.title || ''
})
const bodyBlocks = computed(() => {
  if (headerIdx.value > -1) return blocks.value.toSpliced(headerIdx.value, 1)
  return blocks.value
})
const hasBody = computed(() => bodyBlocks.value.length > 0)
</script>

<style lang="scss" scoped>
.feel-hero {
  border-bottom: 1px solid var(--bs-border-color);
  background: var(--bs-body-bg);
}
.feel-hero__inner {
  max-width: 1320px;
  margin: 0 auto;
  padding: 60px 48px;
  display: grid;
  grid-template-columns: 1fr;
  gap: 60px;
  align-items: center;
}
.feel-hero--with-image .feel-hero__inner {
  grid-template-columns: 1.1fr 1fr;
}
.feel-hero--full {
  min-height: 78vh;
  .feel-hero__inner { min-height: inherit; }
}
.feel-hero__title {
  font-family: 'Cormorant Garamond', Georgia, serif;
  font-weight: 300;
  font-size: clamp(2.4rem, 6vw, 5.5rem);
  line-height: 1.05;
  letter-spacing: -0.01em;
  margin: 0 0 32px;

  :deep(em), :deep(i) {
    font-style: italic;
    color: var(--bs-primary);
    font-weight: 400;
  }
}
.feel-hero__lead {
  font-family: 'Inter', system-ui, sans-serif;
  font-weight: 300;
  font-size: clamp(1rem, 1.3vw, 1.15rem);
  line-height: 1.55;
  color: rgba(0, 0, 0, 0.65);
  max-width: 540px;

  :deep(p) { margin-bottom: 1em; }
  :deep(p:last-child) { margin-bottom: 0; }
  :deep(a) { color: var(--bs-primary); }
}
[data-bs-theme="dark"] .feel-hero__lead { color: rgba(255, 255, 255, 0.7); }

.feel-hero__cta {
  display: inline-flex;
  align-items: center;
  gap: 14px;
  margin-top: 40px;
  padding: 18px 34px;
  background: var(--bs-body-color);
  color: var(--bs-body-bg);
  text-decoration: none;
  font-family: 'Inter', sans-serif;
  font-size: 0.82rem;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  transition: background 0.25s;

  &:hover {
    background: var(--bs-primary);
    color: var(--bs-body-bg);
    text-decoration: none;
  }
  &::after { content: '→'; font-size: 1rem; }
}
.feel-hero__portrait {
  aspect-ratio: 4 / 5;
  background-size: cover;
  background-position: center;
  background-color: var(--bs-tertiary-bg);
}

.feel-hero--simple {
  .feel-hero__inner { padding: 60px 48px 40px; min-height: auto; }
  .feel-hero__title { font-size: clamp(2rem, 4vw, 3.6rem); margin-bottom: 20px; }
  .feel-hero__lead { font-size: 1rem; }
}

@media (max-width: 900px) {
  .feel-hero--with-image .feel-hero__inner { grid-template-columns: 1fr; }
  .feel-hero__inner { padding: 40px 20px; gap: 32px; }
  .feel-hero__portrait { aspect-ratio: 1 / 1; max-height: 60vh; }
}
</style>
