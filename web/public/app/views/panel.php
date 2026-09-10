<?php
/** @var string $name */
$title = 'Panel';
require APP_DIR . '/views/_head.php';
?>
<div class="panel-top"><div class="wrap">
  <?php require APP_DIR . '/views/_logo.php'; ?>
  <strong style="font-family:Sora,sans-serif;font-size:18px">Eskulapp · Panel</strong>
  <span style="margin-left:auto;font-size:14px;color:#BfE0E2">Zalogowano: <?= e($name) ?></span>
  <a class="btn btn-coral" style="padding:8px 16px" href="/wyloguj">Wyloguj</a>
</div></div>

<div class="wrap" style="padding:32px 24px">
  <h1 style="font-size:26px">Twoje wydarzenia</h1>
  <p style="color:var(--muted);margin-top:8px">Stąd zarządzasz eventami, agendą i powiadomieniami. Moduły uruchamiamy przyrostowo.</p>
  <div class="panel-grid">
    <div class="panel-card"><h3>Eventy i kody</h3><p>Twórz wydarzenia, generuj kody dostępu (np. FND2027).</p><span class="badge-soon">w budowie</span></div>
    <div class="panel-card"><h3>Agenda</h3><p>Dni, sale, prelekcje i prelegenci.</p><span class="badge-soon">w budowie</span></div>
    <div class="panel-card"><h3>Partnerzy i mapa</h3><p>Stoiska, loga, plan przestrzeni.</p><span class="badge-soon">w budowie</span></div>
    <div class="panel-card"><h3>Aktualności</h3><p>Ogłoszenia, zmiany sal, promocje.</p><span class="badge-soon">w budowie</span></div>
    <div class="panel-card"><h3>Powiadomienia push</h3><p>Zaplanuj wysyłkę (promo/zmiany/info).</p><span class="badge-soon">w budowie</span></div>
    <div class="panel-card"><h3>Leady z WWW</h3><p>Zgłoszenia organizatorów z formularza.</p><span class="badge-soon">w budowie</span></div>
  </div>
</div>
</body>
</html>
