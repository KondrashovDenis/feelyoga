<!DOCTYPE HTML>
{*
  OVERLAY upstream email.tpl.
  Убран блок с лого Orbita (`{$.env.SITE_URL}email/logo.png`) — это default-картинка движка,
  для нашего проекта неуместна. Вместо лого — текстовая шапка с названием домена.

  Дизайн: светлая палитра, серифный шрифт (Cormorant Garamond) для заголовка/шапки —
  совпадает со стилем сайта filippov.yoga (см. frontend/.../_variables.scss).
*}
<html lang="ru">
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1"/>
    <title>{$.env.SITE_NAME}</title>
    <style>
        body {
            background: #fafaf8;
            margin: 0;
            padding: 0;
            width: 100%;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Arial, sans-serif;
            font-size: 15px;
            line-height: 1.55;
            color: #1a1a1a;
        }
        table { border-spacing: 0; width: 100% }
        table td { margin: 0 }
        a { color: #6b7d5f; text-decoration: none }
        a:hover { text-decoration: underline }
        pre { padding: 10px; background: #f5f5f5; border-radius: 4px; white-space: pre-line }
        img { max-width: 100%; display: block; margin: auto; }

        .main { width: 600px; max-width: 100%; margin: auto }
        .header { padding: 40px 0 20px; text-align: center }
        .header__brand {
            font-family: "Cormorant Garamond", Georgia, serif;
            font-size: 28px;
            font-weight: 400;
            font-style: italic;
            letter-spacing: 0.02em;
            color: #1a1a1a;
        }
        .header__brand a { color: inherit }
        .content {
            background: #ffffff;
            border: 1px solid #e8e6df;
            border-radius: 4px;
            padding: 40px;
        }
        .content h1, .content h2 {
            font-family: "Cormorant Garamond", Georgia, serif;
            font-weight: 400;
            margin: 0 0 20px;
            color: #1a1a1a;
        }
        .content h2 { font-size: 24px }
        .content p { margin: 0 0 16px }
        .content .button {
            display: inline-block;
            padding: 14px 28px;
            background: #1a1a1a;
            color: #fafaf8 !important;
            text-decoration: none;
            font-size: 13px;
            letter-spacing: 0.12em;
            text-transform: uppercase;
            margin: 12px 0;
        }
        .content .button:hover { background: #6b7d5f; text-decoration: none }
        .footer { padding: 30px 0 40px; color: #888; font-size: 13px; text-align: center }
        .footer a { color: #888 }
        .footer__divider { margin: 0 8px; color: #ccc }

        {block 'style'}{/block}
    </style>
</head>
<body>
<table class="main">
    <thead>
    <tr>
        <td class="header">
            <div class="header__brand">
                <a href="{$.env.SITE_URL}" target="_blank">{$.env.SITE_NAME}</a>
            </div>
        </td>
    </tr>
    </thead>
    <tbody>
    <tr>
        {block 'content-wrapper'}
            <td class="content">
                {block 'content'}{/block}
            </td>
        {/block}
    </tr>
    </tbody>
    <tfoot>
    <tr>
        <td class="footer">
            <a href="{$.env.SITE_URL}" target="_blank">{$.env.SITE_NAME}</a>
            <span class="footer__divider">·</span>
            По техническим вопросам: <a href="mailto:admin@filippov.yoga">admin@filippov.yoga</a>
        </td>
    </tr>
    </tfoot>
</table>
</body>
</html>
