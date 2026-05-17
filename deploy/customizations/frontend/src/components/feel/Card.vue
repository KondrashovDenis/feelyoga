<template>
  <NuxtLink :to="link" class="feel-card">
    <div class="feel-card__img" :style="imgStyle" />
    <div v-if="category" class="feel-card__tag">{{ category }}</div>
    <h3 class="feel-card__title">{{ topic.title }}</h3>
    <div v-if="topic.teaser" class="feel-card__teaser">{{ topic.teaser }}</div>
  </NuxtLink>
</template>

<script setup lang="ts">
const props = defineProps<{ topic: any }>()
const {$image, $settings} = useNuxtApp()

const cover = computed(() => props.topic.cover || $settings.value.cover)
const imgStyle = computed(() => {
  if (!cover.value) return {backgroundColor: 'var(--bs-tertiary-bg)'}
  const url = $image(cover.value, {w: 600, h: 750, fit: 'crop'})
  return {backgroundImage: `url('${url}')`}
})
const category = computed(() => props.topic.category?.title || '')
const link = computed(() => ({
  name: 'topics-uuid',
  params: {
    topics: props.topic.category?.uri || 'topics',
    uuid: props.topic.uuid,
  },
}))
</script>

<style lang="scss" scoped>
.feel-card {
  display: block;
  text-decoration: none;
  color: inherit;
  transition: transform 0.25s;

  &:hover {
    transform: translateY(-4px);
    text-decoration: none;
    color: inherit;
  }
}
.feel-card__img {
  aspect-ratio: 4 / 5;
  background-size: cover;
  background-position: center;
  margin-bottom: 20px;
  filter: brightness(0.94);
  transition: filter 0.25s;
}
.feel-card:hover .feel-card__img { filter: brightness(1); }

.feel-card__tag {
  font-family: 'Inter', sans-serif;
  font-size: 0.7rem;
  font-weight: 400;
  letter-spacing: 0.15em;
  text-transform: uppercase;
  color: rgba(0, 0, 0, 0.55);
  margin-bottom: 8px;
}
[data-bs-theme="dark"] .feel-card__tag { color: rgba(255, 255, 255, 0.55); }

.feel-card__title {
  font-family: 'Cormorant Garamond', Georgia, serif;
  font-weight: 400;
  font-size: 1.5rem;
  line-height: 1.2;
  margin: 0 0 8px;
}
.feel-card__teaser {
  font-family: 'Inter', sans-serif;
  font-size: 0.9rem;
  font-weight: 300;
  color: rgba(0, 0, 0, 0.6);
}
[data-bs-theme="dark"] .feel-card__teaser { color: rgba(255, 255, 255, 0.6); }
</style>
