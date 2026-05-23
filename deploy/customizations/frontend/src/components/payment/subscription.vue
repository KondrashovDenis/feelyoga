<template>
  <div>
    <div v-if="currentLevel" class="levels">
      <div class="item">
        <div>{{ t('components.payment.subscription.level.current') }}</div>
        <div class="fw-bold py-1">
          {{ currentLevel.title }}
        </div>
        <div>{{ $price(currentLevel.price) }} {{ t('models.level.per_month') }}</div>
      </div>
      <div class="item active">
        <div>{{ t('components.payment.subscription.level.new') }}</div>
        <div class="fw-bold py-1">
          {{ level.title }}
        </div>
        <div>{{ $price(level.price) }} {{ t('models.level.per_month') }}</div>
      </div>
    </div>
    <div v-else class="subscription">
      <div class="fw-bold">
        {{ level.title }}
      </div>
      <div>{{ $price(level.price) }} {{ t('models.level.per_month') }}</div>
    </div>

    <div v-if="periods.length > 1" class="mt-4">
      <div class="fw-bold">
        {{ t('components.payment.subscription.period') }}
      </div>
      <div class="periods mt-1">
        <div v-for="i in periods" :key="i" :class="periodClass(i)" @click="onPeriod(i)">
          {{ t('components.payment.subscription.months', {amount: i}, i) }}
          <!-- OVERLAY: показ скидки рядом с периодом, если discount < 1.0 -->
          <span v-if="discountLabel(i)" class="period-discount">{{ discountLabel(i) }}</span>
        </div>
      </div>
    </div>
    <div class="mt-2 small text-muted" v-text="description" />

    <!-- ФЗ-152 / ЗоЗПП: дисклеймер согласия с офертой при нажатии «Оплатить».
         Implicit acceptance — стандарт РФ для платных подписок (как Tilda/Yookassa).
         Регистрация уже требует явного согласия с ПД (REGISTER_USER_AGREEMENT). -->
    <div class="mt-3 small text-muted offer-disclaimer">
      Нажимая «Оплатить», вы соглашаетесь с
      <NuxtLink to="/pages/offer" target="_blank" rel="noopener">публичной офертой</NuxtLink>
      и
      <NuxtLink to="/pages/refund" target="_blank" rel="noopener">политикой возврата</NuxtLink>.
    </div>
  </div>
</template>

<script setup lang="ts">
/**
 * OVERLAY upstream components/payment/subscription.vue
 * Изменено:
 *  - Pricing учитывает SUBSCRIPTION_DISCOUNTS multiplier из $variables
 *    (то же значение что у PHP-сервера, см. App\Services\SubscriptionPricing).
 *  - На кнопке периода — лейбл "−N%" если для этого периода есть скидка.
 *  - Серверная цена в Payments::buyLevel считается тем же helper'ом,
 *    поэтому сумма в платёжке == сумма на UI.
 */
import {addDays, addMonths, differenceInDays} from 'date-fns'

const props = defineProps({
  modelValue: {
    type: Object,
    default() {
      return {}
    },
  },
})
const emit = defineEmits(['update:modelValue', 'title'])

const {t} = useI18n()
const {$payment, $levels, $variables} = useNuxtApp()
const {user} = useAuth()
const periods = [1, 3, 6, 12]
const currentLevel = ref<VespLevel | undefined>()
const downgrading = ref(false)
const upgrading = ref(false)
const level = computed<VespLevel>(() => $payment.value as unknown as VespLevel)

const myValue = computed<Record<string, any>>({
  get() {
    return props.modelValue
  },
  set(newValue) {
    emit('update:modelValue', newValue)
  },
})

// --- OVERLAY: discount-map из $variables.SUBSCRIPTION_DISCOUNTS ---
// Формат строки: "1:1.0,3:0.95,6:0.90,12:0.75"
const discountMap = computed<Record<number, number>>(() => {
  const raw = ($variables.value?.SUBSCRIPTION_DISCOUNTS as string) || ''
  const map: Record<number, number> = {}
  if (!raw) return map
  for (const pair of raw.split(',')) {
    const [pStr, mStr] = pair.split(':').map((s) => s.trim())
    const period = Number(pStr)
    const mult = Number(mStr)
    if (period > 0 && mult > 0 && mult <= 1) {
      map[period] = mult
    }
  }
  return map
})

function discountFor(period: number): number {
  return discountMap.value[period] ?? 1.0
}

function discountLabel(period: number): string {
  const mult = discountFor(period)
  if (mult >= 1.0) return ''
  const pct = Math.round((1 - mult) * 100)
  return `−${pct}%`
}
// --- /OVERLAY ---

const description = computed(() => {
  const parts = []
  let date = addDays(new Date(), myValue.value.period * 30)
  if (user.value?.subscription?.active_until) {
    if (downgrading.value) {
      date = new Date(user.value?.subscription?.active_until)
    } else if (upgrading.value) {
      const days = Math.round(myValue.value.discount / costPerDay(level.value))
      date = addDays(new Date(), days)
    }
  }
  parts.push(t('components.payment.subscription.month_' + myValue.value.period, {date: formatDateShort(date)}))
  if (downgrading.value || upgrading.value) {
    parts.push(t('components.payment.subscription.free'))
  } else {
    parts.push(t('components.payment.subscription.can_cancel'))
  }

  return parts.join('\n')
})

function costPerDay(level: VespLevel) {
  const cost = Math.round((level.price / 30) * 100) / 100
  return cost > 1 ? Math.round(cost) : cost
}

function periodClass(selected: number) {
  return {
    item: true,
    active: selected === myValue.value.period,
  }
}

function onPeriod(period: number) {
  myValue.value.period = period
  setPrice()
}

function setPrice() {
  if (downgrading.value) {
    myValue.value.price = 0
    return
  }
  upgrading.value = false

  // OVERLAY: цена = base × period × discount_multiplier (та же логика что на сервере)
  const mult = discountFor(myValue.value.period)
  myValue.value.price = Math.round(level.value.price * myValue.value.period * mult * 100) / 100

  if (user.value?.subscription && user.value.subscription.active_until && currentLevel.value) {
    const days = differenceInDays(new Date(user.value.subscription.active_until), new Date())
    if (days > 0) {
      let cost = costPerDay(currentLevel.value)
      if (cost > 1) {
        cost = Math.round(cost)
      }
      myValue.value.discount = cost * days
      if (myValue.value.discount > myValue.value.price) {
        upgrading.value = true
      }
    }
  }
}

emit('title', t('components.payment.subscription.title'))

if (user.value?.subscription) {
  if (user.value.subscription.level_id === level.value.id) {
    useNuxtApp().$payment.value = undefined
  } else {
    emit('title', t('components.payment.subscription.change'))
    if (user.value && user.value.subscription) {
      currentLevel.value = $levels.value.find((i: VespLevel) => i.id === user.value?.subscription?.level_id)
      if (currentLevel.value) {
        downgrading.value = Boolean(currentLevel.value && currentLevel.value.price > level.value.price)
      }
    }
  }
}

myValue.value.period = periods[0]
setPrice()
</script>

<style scoped>
.period-discount {
  display: inline-block;
  margin-left: 6px;
  padding: 1px 6px;
  font-size: 0.72em;
  font-weight: 600;
  color: #6b7d5f;
  background: rgba(107, 125, 95, 0.12);
  border-radius: 3px;
  vertical-align: middle;
}
</style>
