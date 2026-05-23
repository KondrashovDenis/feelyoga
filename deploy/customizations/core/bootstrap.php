<?php

// Overlay-патч: ванильный bootstrap Orbita + инициализация Sentry/GlitchTip SDK.
// Если SENTRY_DSN не задан в .env — Sentry просто не инициализируется, поведение совпадает с upstream.
//
// PII (IP, user data) выключен принудительно — данные пользователей не должны утекать в error tracker
// даже если он self-hosted, см. ФЗ-152. Если когда-то понадобится — включить точечно через scope.

define('BASE_DIR', dirname(__DIR__) . '/');
require_once BASE_DIR . 'core/vendor/autoload.php';

\Vesp\Helpers\Env::loadFile(BASE_DIR . '/.env');

if (!empty($_ENV['SENTRY_DSN']) && class_exists(\Sentry\SentrySdk::class)) {
    \Sentry\init([
        'dsn' => $_ENV['SENTRY_DSN'],
        'environment' => $_ENV['SENTRY_ENVIRONMENT'] ?? ($_ENV['APP_ENV'] ?? 'production'),
        'release' => $_ENV['SENTRY_RELEASE'] ?? null,
        'send_default_pii' => false,
        'traces_sample_rate' => 0.0,
        'profiles_sample_rate' => 0.0,
        'max_breadcrumbs' => 50,
        'before_send' => static function (\Sentry\Event $event): ?\Sentry\Event {
            // strip query string из request URL (могут быть токены/email)
            $request = $event->getRequest();
            if (!empty($request['url'])) {
                $request['url'] = strtok($request['url'], '?');
                unset($request['query_string'], $request['cookies'], $request['headers']);
                $event->setRequest($request);
            }
            return $event;
        },
    ]);
}
