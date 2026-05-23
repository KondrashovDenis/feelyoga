{extends 'email.tpl'}

{*
  OVERLAY upstream user-register.tpl.
  Заменён сухой "<a>link</a>" на нормальное приветственное сообщение
  с кнопкой подтверждения и контактом для технических вопросов.
*}

{block 'content'}
    {var $link = $.env.SITE_URL ~ 'user/confirm/' ~ $user.username ~ '/' ~ $code}

    {if $lang === 'de'}
        <h2>Willkommen bei Filippov Yoga</h2>
        <p>Vielen Dank für Ihre Registrierung. Bitte bestätigen Sie Ihre E-Mail-Adresse, indem Sie auf den unten stehenden Link klicken.</p>
        <p style="text-align: center"><a href="{$link}" class="button">Registrierung bestätigen</a></p>
        <p style="font-size: 13px; color: #666">
            Falls die Schaltfläche nicht funktioniert, kopieren Sie diesen Link in die Adresszeile Ihres Browsers:<br>
            <a href="{$link}">{$link}</a>
        </p>
        <p style="font-size: 13px; color: #666">
            Bei technischen Problemen schreiben Sie an <a href="mailto:admin@filippov.yoga">admin@filippov.yoga</a>.
        </p>
    {elseif $lang === 'ru'}
        <h2>Добро пожаловать на Filippov Yoga</h2>
        <p>Благодарим за регистрацию. Нажмите на кнопку ниже, чтобы подтвердить адрес электронной почты и завершить регистрацию.</p>
        <p style="text-align: center"><a href="{$link}" class="button">Подтвердить регистрацию</a></p>
        <p style="font-size: 13px; color: #666">
            Если кнопка не работает, скопируйте эту ссылку в адресную строку браузера:<br>
            <a href="{$link}">{$link}</a>
        </p>
        <p style="font-size: 13px; color: #666">
            По всем техническим вопросам при работе с сайтом обращайтесь на <a href="mailto:admin@filippov.yoga">admin@filippov.yoga</a>.
        </p>
    {else}
        <h2>Welcome to Filippov Yoga</h2>
        <p>Thank you for registering. Please confirm your email address by clicking the button below.</p>
        <p style="text-align: center"><a href="{$link}" class="button">Confirm registration</a></p>
        <p style="font-size: 13px; color: #666">
            If the button doesn't work, copy this link into your browser's address bar:<br>
            <a href="{$link}">{$link}</a>
        </p>
        <p style="font-size: 13px; color: #666">
            For any technical issues, please write to <a href="mailto:admin@filippov.yoga">admin@filippov.yoga</a>.
        </p>
    {/if}
{/block}
