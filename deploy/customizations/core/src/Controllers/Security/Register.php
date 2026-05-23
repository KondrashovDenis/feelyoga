<?php

namespace App\Controllers\Security;

use App\Models\User;
use App\Services\YandexCaptcha;
use Psr\Http\Message\ResponseInterface;
use Throwable;
use Vesp\Controllers\Controller;

/**
 * OVERLAY upstream Register.
 *
 * Добавлено:
 *  - проверка Yandex SmartCaptcha токена (если YANDEX_CAPTCHA_SECRET задан в .env)
 *    защищает регистрацию от ботов, ФЗ-152 compliant (заменяет Cloudflare Turnstile).
 */
class Register extends Controller
{
    public function post(): ResponseInterface
    {
        // 1. ФЗ-152 — согласие на обработку персданных
        if (getenv('REGISTER_USER_AGREEMENT') && !$this->getProperty('agree')) {
            return $this->failure('errors.register.no_agreement');
        }

        // 2. SmartCaptcha (если включена)
        if (YandexCaptcha::enabled()) {
            $token = (string)$this->getProperty('captcha_token');
            $ip = $this->getClientIp();
            if (!YandexCaptcha::verify($token, $ip)) {
                return $this->failure('errors.register.captcha_failed');
            }
        }

        $data = array_filter($this->getProperties(), static function ($key) {
            return in_array($key, ['username', 'fullname', 'password', 'email']);
        }, ARRAY_FILTER_USE_KEY);

        try {
            $user = User::createUser($data);
        } catch (Throwable $e) {
            return $this->failure($e->getMessage());
        }

        $lang = $this->request->getHeaderLine('Content-Language') ?: 'en';
        $subject = getenv('EMAIL_REGISTER_' . strtoupper($lang));
        $data = ['user' => $user->toArray(), 'code' => $user->resetPassword(), 'lang' => $lang];
        if ($error = $user->sendEmail($subject, 'user-register', $data)) {
            return $this->failure($error);
        }

        return $this->success();
    }

    /**
     * Достоверный IP клиента из заголовков прокси Caddy → nginx → php-fpm.
     */
    private function getClientIp(): ?string
    {
        $headers = $this->request->getHeaders();
        $xff = $headers['X-Forwarded-For'][0] ?? '';
        if ($xff) {
            return trim(explode(',', $xff)[0]);
        }
        $realIp = $headers['X-Real-IP'][0] ?? '';
        if ($realIp) {
            return trim($realIp);
        }
        return $this->request->getServerParams()['REMOTE_ADDR'] ?? null;
    }
}
