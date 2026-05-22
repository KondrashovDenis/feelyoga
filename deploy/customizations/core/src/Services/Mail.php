<?php

namespace App\Services;

use Pelago\Emogrifier\CssInliner;
use PHPMailer\PHPMailer\Exception;
use PHPMailer\PHPMailer\PHPMailer;
use Throwable;

class Mail
{
    public function send(string $to, string $subject, string $tpl, ?array $data = []): ?string
    {
        if (!getenv('SMTP_HOST')) {
            return null;
        }
        $mail = new PHPMailer(true);
        $mail->CharSet = 'UTF-8';

        // Transport
        $mail->isSMTP();
        $mail->Host = getenv('SMTP_HOST');
        $mail->SMTPAuth = (bool)getenv('SMTP_USER');
        $mail->Username = getenv('SMTP_USER');
        $mail->Password = getenv('SMTP_PASS');
        $mail->SMTPSecure = getenv('SMTP_PROTO');
        $mail->Port = getenv('SMTP_PORT');
        $mail->SMTPDebug = 0;

        $mail->isHTML();
        $mail->Subject = $subject;

        try {
            // Recipients
            $mail->addAddress($to);
            // [feelyoga overlay] SMTP_FROM — отдельный from-адрес (для UniSender Go где SMTP_USER=user_id, а from=email).
            // Fallback на SMTP_USER сохраняет обратную совместимость с upstream Orbita.
            // Сейчас не используется (VK SMTP, login=from), но оставлено на будущее.
            $fromAddress = getenv('SMTP_FROM') ?: getenv('SMTP_USER');
            $mail->setFrom($fromAddress, getenv('SMTP_USER_NAME'));

            if (!str_ends_with($tpl, '.tpl')) {
                $tpl .= '.tpl';
            }
            // Content
            $body = (new Fenom())->fetch($tpl, $data);
            $mail->Body = CssInliner::fromHtml($body)->inlineCss()->render();
            $mail->AltBody = $mail->html2text(nl2br($mail->Body));

            $mail->send();

            return null;
        } catch (Exception $e) {
            Log::error($e);

            return $mail->ErrorInfo;
        } catch (Throwable $e) {
            Log::error($e);

            return $e->getMessage();
        }
    }
}
