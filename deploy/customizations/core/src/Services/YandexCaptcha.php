<?php

namespace App\Services;

/**
 * Yandex SmartCaptcha — серверная верификация токена.
 *
 * Используется в public-эндпоинтах (Register, Reset password) для защиты от ботов.
 * Заменяет Cloudflare Turnstile, которая требует трансграничной передачи (США).
 *
 * ФЗ-152: Yandex Cloud — российский провайдер, ПДн не пересекают границу.
 *
 * Если YANDEX_CAPTCHA_SECRET не задан в .env — verify пропускается (dev mode).
 *
 * API: https://yandex.cloud/ru/docs/smartcaptcha/concepts/validation
 */
class YandexCaptcha
{
    private const VERIFY_URL = 'https://smartcaptcha.yandexcloud.net/validate';
    private const TIMEOUT_SECONDS = 10;

    public static function enabled(): bool
    {
        return !empty(getenv('YANDEX_CAPTCHA_SECRET'));
    }

    /**
     * Проверка токена через Yandex SmartCaptcha.
     *
     * @param string|null $token   Токен с фронта (из callback SmartCaptcha widget)
     * @param string|null $remoteIp IP клиента (для antifraud, опционально)
     */
    public static function verify(?string $token, ?string $remoteIp = null): bool
    {
        if (!self::enabled()) {
            return true; // dev mode без ключей
        }
        if (empty($token)) {
            return false;
        }

        $params = [
            'secret' => getenv('YANDEX_CAPTCHA_SECRET'),
            'token' => $token,
        ];
        if ($remoteIp) {
            $params['ip'] = $remoteIp;
        }

        $ch = curl_init(self::VERIFY_URL);
        curl_setopt_array($ch, [
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => http_build_query($params),
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => self::TIMEOUT_SECONDS,
            CURLOPT_HTTPHEADER => ['Content-Type: application/x-www-form-urlencoded'],
        ]);
        $body = curl_exec($ch);
        $err = curl_error($ch);
        curl_close($ch);

        if ($body === false) {
            error_log("YandexCaptcha network error: $err");
            return false;
        }

        $data = json_decode($body, true);
        if (!is_array($data)) {
            error_log("YandexCaptcha invalid JSON: " . substr((string)$body, 0, 200));
            return false;
        }

        // Yandex отвечает {"status": "ok"|"failed", "message": "..."}
        return ($data['status'] ?? '') === 'ok';
    }
}
