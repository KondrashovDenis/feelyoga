<?php

namespace App\Services;

/**
 * Discount-map для подписки по длительности периода.
 *
 * Format env-переменной SUBSCRIPTION_DISCOUNTS:
 *   "1:1.0,3:0.95,6:0.90,12:0.75"
 * где ключ — длительность периода в месяцах, значение — множитель (0..1).
 *
 * Если SUBSCRIPTION_DISCOUNTS не задан или для периода нет записи —
 * множитель = 1.0 (без скидки, поведение совпадает с upstream).
 *
 * Использовать единый helper из Level::costForPeriod и Subscription::amountForPeriod,
 * чтобы серверная цена не расходилась с клиентской при оплате.
 */
class SubscriptionPricing
{
    /** @var array<int,float>|null */
    private static ?array $cache = null;

    /**
     * @return array<int,float> map period (months) → discount multiplier
     */
    public static function discounts(): array
    {
        if (self::$cache !== null) {
            return self::$cache;
        }

        $raw = (string)(getenv('SUBSCRIPTION_DISCOUNTS') ?: '');
        $map = [];
        if ($raw !== '') {
            foreach (explode(',', $raw) as $pair) {
                $parts = explode(':', trim($pair), 2);
                if (count($parts) !== 2) {
                    continue;
                }
                $period = (int)trim($parts[0]);
                $mult = (float)trim($parts[1]);
                if ($period > 0 && $mult > 0 && $mult <= 1.0) {
                    $map[$period] = $mult;
                }
            }
        }
        self::$cache = $map;
        return $map;
    }

    /**
     * Финальная стоимость = basePrice × period × discount(period).
     * Если для period нет discount → multiplier = 1.0.
     */
    public static function calculate(float $basePrice, int $period): float
    {
        $period = max(1, $period);
        $mult = self::discounts()[$period] ?? 1.0;
        return round($basePrice * $period * $mult, 2);
    }

    /**
     * Discount-множитель для периода (0..1). 1.0 если нет скидки.
     */
    public static function multiplier(int $period): float
    {
        return self::discounts()[$period] ?? 1.0;
    }
}
