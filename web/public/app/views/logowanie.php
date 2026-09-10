<?php
/** @var string $error @var string $notice */
$error  = $error  ?? '';
$notice = $notice ?? '';
$title  = 'Panel organizatora';
require APP_DIR . '/views/_head.php';
?>
<div class="auth-page">
  <div class="auth-card">
    <div class="auth-brand"><?php require APP_DIR . '/views/_logo.php'; ?>Eskulapp</div>
    <h1>Panel organizatora</h1>
    <div class="authsub">Zaloguj się, aby zarządzać wydarzeniami</div>
    <?php if ($notice): ?><div class="notice"><?= e($notice) ?></div><?php endif; ?>
    <?php if ($error): ?><div class="msg-err"><?= e($error) ?></div><?php endif; ?>
    <form method="post" action="/logowanie">
      <div class="field"><label>E-mail</label><input type="email" name="email" required autofocus></div>
      <div class="field"><label>Hasło</label><input type="password" name="password" required></div>
      <button class="btn btn-primary" type="submit">Zaloguj się</button>
    </form>
    <a class="auth-back" href="/">Wróć na stronę główną</a>
  </div>
</div>
</body>
</html>
