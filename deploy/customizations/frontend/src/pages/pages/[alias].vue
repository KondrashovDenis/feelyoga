<template>
  <BOverlay :show="loading" opacity="0.5">
    <template v-if="!record">
      <FeelHero
        :page="heroPageData"
        :portrait-image="portraitUrl || undefined"
        :variant="portraitUrl ? 'full' : 'simple'"
      />

      <section v-if="restBlocks.length || canEdit" class="feel-section">
        <div class="feel-section__inner feel-content">
          <div @click="$contentClick">
            <EditorContent v-if="restBlocks.length" :content="{blocks: restBlocks}" />
          </div>
          <BButton v-if="canEdit" variant="link" class="ms-2 p-0 feel-edit-btn" @click="onEdit">
            <VespFa icon="edit" class="fa-fw" /> Редактировать
          </BButton>
        </div>
      </section>
    </template>

    <BForm v-else-if="canEdit" class="topic-form col-md-9 m-auto" @submit.prevent="onSubmit" @keydown="onKeydown">
      <FormsPage v-model="record" />
      <div class="topic-buttons mb-0 mt-2">
        <BButton :disabled="loading" @click.prevent="onCancel">
          {{ $t('actions.cancel') }}
        </BButton>
        <BButton variant="primary" type="submit" :disabled="loading">
          <BSpinner v-if="loading" small />
          {{ $t('actions.save') }}
        </BButton>
      </div>
    </BForm>
  </BOverlay>
</template>

<script setup lang="ts">
const router = useRouter()
const route = useRoute()
const {$settings, $socket, $scope} = useNuxtApp()
const {data, error} = await useCustomFetch('web/pages/' + route.params.alias)
if (error.value) {
  showError({statusCode: error.value.statusCode || 500, statusMessage: error.value.statusMessage || 'Server Error'})
}
const page: ComputedRef<VespPage> = computed(() => data.value || {})
const loading = ref(false)
const record: Ref<undefined | VespPage> = ref()

const canEdit = computed(() => $scope('pages/patch'))

// Первый image-блок → portrait в Hero, остальное идёт дальше как обычно
const {portraitUrl, blocksWithoutPortrait} = usePagePortrait(page)

// Hero: h1 + первый paragraph как lead (работаем над blocksWithoutPortrait)
const headerIdx = computed(() => blocksWithoutPortrait.value.findIndex((b) => b.type === 'header' && b.data?.level === 1))
const heroBlocks = computed<any[]>(() => {
  const arr: any[] = []
  if (headerIdx.value > -1) arr.push(blocksWithoutPortrait.value[headerIdx.value])
  else if (page.value.title) arr.push({id: 'h1', type: 'header', data: {text: page.value.title, level: 1}})

  // Первый параграф после header — это lead
  const afterHeader = headerIdx.value > -1
    ? blocksWithoutPortrait.value.slice(headerIdx.value + 1)
    : blocksWithoutPortrait.value
  const firstParagraph = afterHeader.find((b) => b.type === 'paragraph')
  if (firstParagraph) arr.push(firstParagraph)
  return arr
})
const heroPageData = computed(() => ({
  title: page.value.title,
  content: {blocks: heroBlocks.value},
}))

// Остальной контент (всё после Hero h1 + первого параграфа)
const restBlocks = computed<any[]>(() => {
  const remaining = headerIdx.value > -1
    ? blocksWithoutPortrait.value.toSpliced(headerIdx.value, 1)
    : [...blocksWithoutPortrait.value]
  const firstParaIdx = remaining.findIndex((b) => b.type === 'paragraph')
  return firstParaIdx > -1 ? remaining.toSpliced(firstParaIdx, 1) : remaining
})

async function onEdit() {
  try {
    loading.value = true
    record.value = await useGet('admin/pages/' + page.value.id)
  } catch (e) {
  } finally {
    loading.value = false
  }
}

async function onSubmit() {
  try {
    loading.value = true
    scrollToTop()
    const data = await usePatch('admin/pages/' + page.value.id, {...record.value})
    if (data.external) {
      await router.push({name: 'index', replace: true})
    } else {
      onCancel()
    }
  } catch (e) {
  } finally {
    loading.value = false
  }
}

function onCancel() {
  record.value = undefined
}

function onUpdatePage(data: VespPage) {
  if (data.id !== page.value.id) return
  if (page.value.alias !== data.alias) {
    useRouter().replace({name: 'pages-alias', params: {alias: data.alias}})
  } else {
    page.value.title = data.title
    page.value.content = data.content
  }
}

function onKeydown(e: KeyboardEvent) {
  if ((e.ctrlKey || e.metaKey) && e.key === 's') {
    e.preventDefault()
    onSubmit()
  }
}

onMounted(() => {
  $socket.on('page-update', onUpdatePage)
  if (error.value) clearError()
})
onUnmounted(() => {
  $socket.off('page-update', onUpdatePage)
})

useHead({
  title: () => [page.value?.title, $settings.value.title].join(' / '),
})
</script>

<style lang="scss" scoped>
.feel-section { padding: 60px 0 100px; }
.feel-section__inner {
  max-width: 900px;
  margin: 0 auto;
  padding: 0 48px;
}
.feel-content {
  font-family: 'Inter', sans-serif;
  font-weight: 300;
  font-size: 1.05rem;
  line-height: 1.7;

  :deep(p) { margin-bottom: 1.2em; }
  :deep(h2) {
    font-family: 'Cormorant Garamond', Georgia, serif;
    font-weight: 400;
    font-size: 2rem;
    margin: 1.5em 0 0.6em;
  }
  :deep(h3) {
    font-family: 'Cormorant Garamond', Georgia, serif;
    font-weight: 400;
    font-size: 1.6rem;
    margin: 1.3em 0 0.5em;
  }
  :deep(a) { color: var(--bs-primary); }
  :deep(img) { max-width: 100%; height: auto; }
  :deep(blockquote) {
    border-left: 3px solid var(--bs-primary);
    padding-left: 1.5em;
    margin: 1.5em 0;
    font-style: italic;
    font-family: 'Cormorant Garamond', Georgia, serif;
    font-size: 1.3rem;
  }
}
.feel-edit-btn {
  margin-top: 2em;
  font-family: 'Inter', sans-serif;
  font-size: 0.85rem;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}

@media (max-width: 900px) {
  .feel-section__inner { padding: 0 20px; }
}
</style>
