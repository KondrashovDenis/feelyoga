<template>
  <div class="landing-page">
    <!-- HERO — full-width текст слева + портрет справа -->
    <FeelHero
      :page="heroPage"
      :portrait-image="portraitImage"
      :cta="{text: 'Смотреть практики', href: '#practices'}"
      variant="full"
    />

    <!-- ПРАКТИКИ — editorial grid -->
    <section id="practices" class="feel-section">
      <div class="feel-section__inner">
        <div class="feel-section__head">
          <span class="feel-tag">Видеотека</span>
          <h2 class="feel-h2">Записанные <em>классы</em><br>и медитации</h2>
        </div>

        <div v-if="topics.length" class="feel-grid">
          <FeelCard v-for="t in topics" :key="t.id" :topic="t" />
        </div>
        <div v-else class="feel-empty">Пока пусто. Михаил скоро добавит первые видео.</div>
      </div>
    </section>

    <!-- ABOUT -->
    <section id="about" class="feel-section feel-section--alt">
      <div class="feel-section__inner feel-about">
        <div class="feel-about__img" :style="aboutImgStyle" />
        <div class="feel-about__text">
          <h2 v-if="aboutTitle" class="feel-h2 feel-h2--about" v-html="aboutTitle" />
          <div class="feel-about__body" @click="$contentClick">
            <EditorContent v-if="aboutBody.length" :content="{blocks: aboutBody}" />
          </div>
        </div>
      </div>
    </section>

    <!-- SUBSCRIPTION -->
    <section id="subscription" class="feel-section">
      <div class="feel-section__inner">
        <div class="feel-section__head feel-section__head--center">
          <span class="feel-tag">Подписка</span>
          <h2 class="feel-h2" v-html="subscriptionTitle" />
          <div v-if="subscriptionLead.length" class="feel-subscription__lead">
            <EditorContent :content="{blocks: subscriptionLead}" />
          </div>
        </div>

        <div class="feel-pricing">
          <div v-for="level in levels" :key="level.id" class="feel-pricing__card">
            <div class="feel-pricing__name">{{ level.title }}</div>
            <div class="feel-pricing__price">
              {{ level.price }}<small> ₽ / месяц</small>
            </div>
            <div class="feel-pricing__body" @click="$contentClick">
              <EditorContent v-if="level.content?.blocks?.length" :content="level.content" />
            </div>
            <NuxtLink :to="{name: 'user-subscription'}" class="feel-pricing__cta">
              Оформить →
            </NuxtLink>
          </div>
          <div v-if="!levels.length" class="feel-empty">Уровни подписки пока не настроены.</div>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
const {$settings, $image} = useNuxtApp()

// fetch параллельно
const [heroResp, aboutResp, subIntroResp, topicsResp, levelsResp] = await Promise.all([
  useCustomFetch('web/pages/home-hero').catch(() => ({data: ref(null)})),
  useCustomFetch('web/pages/about').catch(() => ({data: ref(null)})),
  useCustomFetch('web/pages/subscription-intro').catch(() => ({data: ref(null)})),
  useCustomFetch('web/topics?limit=9&sort=date').catch(() => ({data: ref({rows: []})})),
  useCustomFetch('web/levels').catch(() => ({data: ref({rows: []})})),
])

const heroPage = computed(() => heroResp.data?.value || null)
const aboutPage = computed(() => aboutResp.data?.value || null)
const subIntroPage = computed(() => subIntroResp.data?.value || null)
const topics = computed<any[]>(() => (topicsResp.data?.value as any)?.rows || [])
const levels = computed<any[]>(() => (levelsResp.data?.value as any)?.rows || [])

// Fallback на глобальный settings.poster если в странице нет image-блока
const settingsPosterUrl = computed(() => {
  const poster = $settings.value.poster
  if (!poster) return null
  return $image(poster, {w: 720, h: 900, fit: 'crop'}) || null
})

// Hero — приоритет: image-блок в home-hero → fallback settings.poster
const {portraitUrl: heroPortraitUrl} = usePagePortrait(heroPage)
const portraitImage = computed(() => heroPortraitUrl.value || settingsPosterUrl.value || undefined)

// About — приоритет: image-блок в about → fallback settings.poster
const {portraitUrl: aboutPortraitUrl, blocksWithoutPortrait: aboutBlocksClean} = usePagePortrait(aboutPage)
const aboutHeaderIdx = computed(() => aboutBlocksClean.value.findIndex((b) => b.type === 'header' && b.data?.level === 1))
const aboutTitle = computed(() => {
  if (aboutHeaderIdx.value > -1) return aboutBlocksClean.value[aboutHeaderIdx.value].data.text
  return aboutPage.value?.title || ''
})
const aboutBody = computed(() => {
  if (aboutHeaderIdx.value > -1) return aboutBlocksClean.value.toSpliced(aboutHeaderIdx.value, 1)
  return aboutBlocksClean.value
})
const aboutImgStyle = computed(() => {
  const url = aboutPortraitUrl.value || settingsPosterUrl.value
  if (!url) return {backgroundColor: 'var(--bs-tertiary-bg)'}
  return {backgroundImage: `url('${url}')`}
})

// subscription intro — h1 как title, остальное как lead
const subBlocks = computed<any[]>(() => subIntroPage.value?.content?.blocks || [])
const subHeaderIdx = computed(() => subBlocks.value.findIndex((b) => b.type === 'header' && b.data?.level === 1))
const subscriptionTitle = computed(() => {
  if (subHeaderIdx.value > -1) return subBlocks.value[subHeaderIdx.value].data.text
  return subIntroPage.value?.title || 'Подписка'
})
const subscriptionLead = computed(() => {
  if (subHeaderIdx.value > -1) return subBlocks.value.toSpliced(subHeaderIdx.value, 1)
  return subBlocks.value
})
</script>

<style lang="scss" scoped>
.landing-page { background: var(--bs-body-bg); }

.feel-section {
  border-top: 1px solid var(--bs-border-color);
  padding: 100px 0;
}
.feel-section--alt { background: rgba(0,0,0,0.02); }
[data-bs-theme="dark"] .feel-section--alt { background: rgba(255,255,255,0.02); }

.feel-section__inner {
  max-width: 1320px;
  margin: 0 auto;
  padding: 0 48px;
}

.feel-section__head {
  display: grid;
  grid-template-columns: 1fr 2fr;
  gap: 60px;
  margin-bottom: 60px;
  align-items: end;
}
.feel-section__head--center {
  display: block;
  text-align: center;
  margin-bottom: 60px;
}

.feel-tag {
  font-family: 'Inter', sans-serif;
  font-size: 0.72rem;
  font-weight: 500;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  color: var(--bs-primary);
  display: inline-block;
  margin-bottom: 12px;
}

.feel-h2 {
  font-family: 'Cormorant Garamond', Georgia, serif;
  font-weight: 300;
  font-size: clamp(2rem, 4vw, 3.2rem);
  line-height: 1.1;
  margin: 0;
  max-width: 600px;

  :deep(em), :deep(i) {
    font-style: italic;
    color: var(--bs-primary);
    font-weight: 400;
  }
}
.feel-section__head--center .feel-h2 { margin: 0 auto 16px; max-width: 760px; }
.feel-h2--about { max-width: none; margin-bottom: 28px; }

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

.feel-about {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 80px;
  align-items: center;
}
.feel-about__img {
  aspect-ratio: 4 / 5;
  background-size: cover;
  background-position: center;
  background-color: var(--bs-tertiary-bg);
}
.feel-about__body {
  font-family: 'Inter', sans-serif;
  font-weight: 300;
  font-size: 1.05rem;
  line-height: 1.6;
  color: rgba(0,0,0,0.7);

  :deep(p) { margin-bottom: 1em; }
  :deep(p:last-child) { margin-bottom: 0; }
  :deep(a) { color: var(--bs-primary); }
}
[data-bs-theme="dark"] .feel-about__body { color: rgba(255,255,255,0.75); }

.feel-subscription__lead {
  font-family: 'Inter', sans-serif;
  font-weight: 300;
  color: rgba(0,0,0,0.6);
  max-width: 560px;
  margin: 0 auto;

  :deep(p) { margin: 0 0 1em; }
}
[data-bs-theme="dark"] .feel-subscription__lead { color: rgba(255,255,255,0.65); }

.feel-pricing {
  display: flex;
  justify-content: center;
  gap: 32px;
  flex-wrap: wrap;
}
.feel-pricing__card {
  border: 1px solid var(--bs-border-color);
  padding: 56px 40px;
  max-width: 480px;
  width: 100%;
  background: var(--bs-body-bg);
}
.feel-pricing__name {
  font-family: 'Inter', sans-serif;
  font-size: 0.75rem;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  color: var(--bs-primary);
  margin-bottom: 20px;
  text-align: center;
}
.feel-pricing__price {
  font-family: 'Cormorant Garamond', Georgia, serif;
  font-size: 4rem;
  font-weight: 300;
  margin: 0 0 24px;
  text-align: center;

  small {
    font-family: 'Inter', sans-serif;
    font-size: 1rem;
    color: rgba(0,0,0,0.55);
  }
}
[data-bs-theme="dark"] .feel-pricing__price small { color: rgba(255,255,255,0.55); }

.feel-pricing__body {
  font-family: 'Inter', sans-serif;
  font-size: 0.95rem;
  font-weight: 300;
  color: rgba(0,0,0,0.7);
  margin-bottom: 28px;

  :deep(ul) { list-style: none; padding: 0; margin: 0; }
  :deep(li) {
    padding: 12px 0;
    border-bottom: 1px solid var(--bs-border-color);
    &::before { content: '— '; color: var(--bs-primary); }
  }
  :deep(p) { margin-bottom: 0.8em; }
}
[data-bs-theme="dark"] .feel-pricing__body { color: rgba(255,255,255,0.7); }

.feel-pricing__cta {
  display: inline-flex;
  align-items: center;
  gap: 14px;
  padding: 18px 34px;
  background: var(--bs-body-color);
  color: var(--bs-body-bg);
  text-decoration: none;
  font-family: 'Inter', sans-serif;
  font-size: 0.82rem;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  transition: background 0.25s;
  width: 100%;
  justify-content: center;

  &:hover {
    background: var(--bs-primary);
    color: var(--bs-body-bg);
    text-decoration: none;
  }
}

@media (max-width: 900px) {
  .feel-section { padding: 60px 0; }
  .feel-section__inner { padding: 0 20px; }
  .feel-section__head { grid-template-columns: 1fr; gap: 24px; margin-bottom: 40px; }
  .feel-about { grid-template-columns: 1fr; gap: 32px; }
  .feel-grid { grid-template-columns: 1fr; gap: 32px; }
  .feel-pricing__card { padding: 40px 24px; }
}
</style>
