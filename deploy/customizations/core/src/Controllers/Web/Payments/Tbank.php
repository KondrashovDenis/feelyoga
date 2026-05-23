<?php

namespace App\Controllers\Web\Payments;

use App\Models\Payment;
use App\Services\Log;
use Psr\Http\Message\ResponseInterface;
use Throwable;
use Vesp\Controllers\Controller;

/**
 * Webhook handler для notifications от Tinkoff/T-Bank (Notification URL).
 *
 * Tbank долбит этот endpoint при каждом изменении статуса платежа
 * (Confirmed, Refunded, RebillIdCreated и т.п.). В body приходит JSON
 * с полями TerminalKey, OrderId, Status, PaymentId, Token и др.
 *
 * Стратегия — pull-через-API: не доверяем body webhook'а, дёргаем
 * checkStatus() который делает GetState к Tbank через защищённый канал
 * и обновляет DB. Token signature не валидируем (защита через TLS +
 * проверка статуса в API; даже если злоумышленник отправит фейк OrderId,
 * статус будет браться от Tbank через API).
 *
 * Tbank требует от webhook'а ровно "OK" в body ответа (не JSON), иначе
 * повторяет ретраи с экспоненциальной задержкой до 24h.
 *
 * URL: POST /api/web/payment/tbank
 * Регистрация: deploy/customizations/core/routes.php (overlay)
 */
class Tbank extends Controller
{
    public function post(): ResponseInterface
    {
        $body = (string)$this->request->getBody();
        $data = json_decode($body, true);

        if (!is_array($data)) {
            Log::warn('Tbank webhook: invalid JSON body', ['raw' => substr($body, 0, 500)]);
            return $this->ok();
        }

        $orderId = $data['OrderId'] ?? null;
        if (!$orderId) {
            Log::warn('Tbank webhook: no OrderId', ['data' => $data]);
            return $this->ok();
        }

        /** @var Payment|null $payment */
        $payment = Payment::query()->find($orderId);
        if (!$payment) {
            Log::warn('Tbank webhook: payment not found', ['order_id' => $orderId]);
            return $this->ok();
        }

        try {
            // checkStatus сам дёрнет Tbank::getPaymentStatus → GetState API
            // → обновит paid/paid_at/activate subscription если нужно
            $payment->checkStatus();
        } catch (Throwable $e) {
            Log::error('Tbank webhook: checkStatus failed', [
                'order_id' => $orderId,
                'error' => $e->getMessage(),
            ]);
        }

        return $this->ok();
    }

    /**
     * Tbank ожидает в теле ответа ровно "OK" (text/plain), иначе повторяет.
     */
    private function ok(): ResponseInterface
    {
        $response = $this->response->withHeader('Content-Type', 'text/plain');
        $response->getBody()->write('OK');
        return $response;
    }
}
