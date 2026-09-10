<?php
/** @var string $error @var string $notice @var string $csrf */
$error  = $error  ?? '';
$notice = $notice ?? '';
$csrf   = $csrf   ?? '';
$title  = 'Logowanie';
require APP_DIR . '/views/_head.php';
?>
<div class="auth-page">
  <div class="auth-card">
    <div class="auth-brand"><?php require APP_DIR . '/views/_logo.php'; ?>Eskulapp</div>
    <h1>Panel administracyjny</h1>
    <div class="authsub">Dostęp tylko dla administracji Eskulapp</div>
    <?php if ($notice): ?><div class="notice"><?= e($notice) ?></div><?php endif; ?>
    <?php if ($error): ?><div class="msg-err"><?= e($error) ?></div><?php endif; ?>
    <form method="post" action="<?= BASE ?>/logowanie" autocomplete="off">
      <input type="hidden" name="_csrf" value="<?= e($csrf) ?>">
      <div class="field"><label>E-mail</label><input type="email" name="email" required autofocus></div>
      <div class="field"><label>Hasło</label><input type="password" name="password" required></div>
      <button class="btn btn-primary" type="submit">Zaloguj się</button>
    </form>
  </div>
</div>
</body>
</html>
