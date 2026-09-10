<?php
/** @var string $name @var array $events */
$name = $name ?? 'Admin';
$events = $events ?? [];
$title = 'Panel';
require APP_DIR . '/views/_head.php';
?>
<div class="panel-top"><div class="wrap">
  <?php require APP_DIR . '/views/_logo.php'; ?>
  <strong style="font-family:Sora,sans-serif;font-size:18px">Eskulapp · Panel</strong>
  <span style="margin-left:auto;font-size:14px;color:#BfE0E2">Zalogowano: <?= e($name) ?></span>
  <a class="btn btn-coral" style="padding:8px 16px" href="<?= BASE ?>/wyloguj">Wyloguj</a>
</div></div>

<div class="wrap" style="padding:32px 24px">
  <div style="display:flex;align-items:center;gap:14px;flex-wrap:wrap">
    <h1 style="font-size:26px">Wydarzenia</h1>
    <a class="btn btn-primary" style="margin-left:auto" href="<?= BASE ?>/events/new">
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5v14M5 12h14"/></svg>
      Nowy event
    </a>
  </div>
  <p style="color:#5B6B72;margin-top:8px;max-width:640px">Eventy tworzy admin lub agent i nadaje im kod dostępu (np. FND2027). Organizatorzy nie zakładają eventów sami, zgłoszenia z formularza to zapytania sprzedażowe.</p>

  <?php if (!$events): ?>
    <div class="panel-card" style="margin-top:22px">
      <h3>Brak wydarzeń</h3>
      <p>Kliknij „Nowy event", aby utworzyć pierwsze wydarzenie i nadać kod dostępu.</p>
    </div>
  <?php else: ?>
    <div class="ev-table" style="margin-top:22px">
      <?php foreach ($events as $ev): ?>
        <a class="ev-row" href="<?= BASE ?>/events/<?= (int)$ev['id'] ?>">
          <div class="ev-name"><?= e($ev['name']) ?><span class="ev-meta"><?= e($ev['city'] ?? 'miasto do ustalenia') ?> · <?= e($ev['starts_at'] ?? 'termin do ustalenia') ?></span></div>
          <span class="ev-code"><?= e($ev['access_code']) ?></span>
          <span class="ev-status ev-<?= e($ev['status']) ?>"><?= e($ev['status']) ?></span>
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#C7D0D4" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 6l6 6-6 6"/></svg>
        </a>
      <?php endforeach; ?>
    </div>
  <?php endif; ?>

  <div class="panel-grid" style="margin-top:26px">
    <div class="panel-card"><h3>Agenda</h3><p>Dni, sale, prelekcje, prelegenci.</p><span class="badge-soon">następny moduł</span></div>
    <div class="panel-card"><h3>Partnerzy i mapa</h3><p>Stoiska, loga, plan przestrzeni.</p><span class="badge-soon">w budowie</span></div>
    <div class="panel-card"><h3>Aktualności i push</h3><p>Ogłoszenia, zmiany, powiadomienia.</p><span class="badge-soon">w budowie</span></div>
    <div class="panel-card"><h3>Leady z WWW</h3><p>Zapytania z formularza kontaktowego.</p><span class="badge-soon">w budowie</span></div>
  </div>
</div>
</body>
</html>
