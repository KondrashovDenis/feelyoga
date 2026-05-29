/**
 * Извлекает первый image-блок из page.content как portrait + возвращает
 * blocks без него (чтобы не дублировался в body).
 *
 * Паттерн: Михаил в админке вставляет картинку первым (или любым) image-блоком
 * на странице — она автоматически идёт в боковую колонку (Hero portrait,
 * About sidebar и т.п.), остальной контент рендерится как тело.
 *
 * Если image-блока нет — portraitUrl=null, fallback на settings.poster делает
 * вызывающая сторона.
 */
export function usePagePortrait(
  pageRef: Ref<any> | ComputedRef<any>,
  imageOpts: Record<string, any> = {w: 720, h: 900, fit: 'crop'},
) {
  const {$image} = useNuxtApp()

  const blocks = computed<any[]>(() => pageRef.value?.content?.blocks || [])

  const imageIdx = computed(() => blocks.value.findIndex((b) => b.type === 'image'))

  const portraitFile = computed(() => {
    if (imageIdx.value < 0) return null
    return blocks.value[imageIdx.value]?.data?.file || null
  })

  const portraitUrl = computed<string | null>(() => {
    if (!portraitFile.value) return null
    return $image(portraitFile.value, imageOpts) || null
  })

  const blocksWithoutPortrait = computed<any[]>(() => {
    if (imageIdx.value < 0) return blocks.value
    return blocks.value.toSpliced(imageIdx.value, 1)
  })

  return {portraitFile, portraitUrl, blocksWithoutPortrait}
}
