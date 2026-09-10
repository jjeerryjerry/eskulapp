<?php
/** @var array $ev @var array $errors @var string $csrf @var bool $isNew */
$ev = $ev ?? [];
$errors = $errors ?? [];
$csrf = $csrf ?? '';
$isNew = $isNew ?? true;
$val = fn(string $k, $d = '') => e((string)($ev[$k] ?? $d));
$dtval = function (?string $v) { if (!$v) return ''; return e(substr(str_replace(' ', 'T', $v), 0, 16)); };
$title = $isNew ? 'Nowy event' : 'Edycja eventu';
require APP_DIR . '/views/_head.php';
?>
<div class="panel-top"><div class="wrap">
  <?php require APP_DIR . '/views/_logo.php'; ?>
  <strong style="font-family:Sora,sans-serif;font-size:18px">Eskulapp · Panel</strong>
  <a class="btn btn-ghost" style="margin-left:auto;padding:8px 16px" href="<?= BASE ?>/dashboard">Wróć</a>
</div></div>

<div class="wrap" style="padding:32px 24px;max-width:720px">
  <h1 style="font-size:26px"><?= e($title) ?></h1>
  <?php if ($errors): ?><div class="msg-err" style="margin-top:14px">Popraw zaznaczone pola.</div><?php endif; ?>

  <form method="post" action="<?= BASE ?>/events<?= $isNew ? '' : '/' . (int)$ev['id'] ?>" style="margin-top:18px">
    <input type="hidden" name="_csrf" value="<?= e($csrf) ?>">

    <div class="field">
      <label>Nazwa wydarzenia</label>
      <input name="name" required value="<?= $val('name') ?>">
      <?php if (isset($errors['name'])): ?><div class="ferr"><?= e($errors['name']) ?></div><?php endif; ?>
    </div>

    <div class="ev-2col">
      <div class="field">
        <label>Kod dostępu <span style="color:var(--faint)">(puste = wygenerujemy)</span></label>
        <input name="access_code" value="<?= $val('access_code') ?>" placeholder="np. FND2027" style="text-transform:uppercase;font-family:Sora,sans-serif;letter-spacing:.08em">
        <?php if (isset($errors['access_code'])): ?><div class="ferr"><?= e($errors['access_code']) ?></div><?php endif; ?>
      </div>
      <div class="field">
        <label>Status</label>
        <select name="status">
          <?php foreach (['draft'=>'Szkic','published'=>'Opublikowany','archived'=>'Archiwalny'] as $k=>$lbl): ?>
            <option value="<?= $k ?>" <?= ($ev['status'] ?? 'draft')===$k?'selected':'' ?>><?= $lbl ?></option>
          <?php endforeach; ?>
        </select>
      </div>
    </div>

    <div class="ev-2col">
      <div class="field"><label>Początek</label><input type="datetime-local" name="starts_at" value="<?= $dtval($ev['starts_at'] ?? null) ?>"></div>
      <div class="field"><label>Koniec</label><input type="datetime-local" name="ends_at" value="<?= $dtval($ev['ends_at'] ?? null) ?>"></div>
    </div>

    <div class="ev-2col">
      <div class="field"><label>Miasto</label><input name="city" value="<?= $val('city') ?>"></div>
      <div class="field"><label>Miejsce (obiekt)</label><input name="venue_name" value="<?= $val('venue_name') ?>"></div>
    </div>

    <div class="field">
      <label style="display:flex;align-items:center;gap:9px;cursor:pointer">
        <input type="checkbox" name="is_closed" value="1" <?= !isset($ev['is_closed'])||$ev['is_closed']?'checked':'' ?> style="width:auto">
        Zamknięte (wymaga kodu dostępu)
      </label>
    </div>

    <div style="display:flex;gap:12px;align-items:center;margin-top:22px">
      <button class="btn btn-primary" type="submit"><?= $isNew ? 'Utwórz event' : 'Zapisz zmiany' ?></button>
      <a class="btn btn-ghost" href="<?= BASE ?>/dashboard">Anuluj</a>
      <?php if (!$isNew): ?>
        <button class="btn" formaction="<?= BASE ?>/events/<?= (int)$ev['id'] ?>/delete" formmethod="post"
                style="margin-left:auto;color:var(--coral-d);background:var(--coral-tint)"
                onclick="return confirm('Usunąć event i całą jego treść?')">Usuń</button>
      <?php endif; ?>
    </div>
  </form>
</div>
</body>
</html>
