<?php
/**
 * Oceny prelekcji eventu (SPEC-OCENY §6): tabela prelekcji + ranking prelegentow.
 * @var array $ev @var array $report @var string $tab @var string $sort @var string $dir
 */
$title = 'Oceny · ' . ($ev['name'] ?? '');
$base = BASE . '/events/' . (int)$ev['id'] . '/oceny';
$qs = fn(array $p) => '?' . http_build_query($p);
$num = fn(?float $v, int $d = 1) => $v === null ? 'brak' : number_format($v, $d, ',', '');
$sortLink = function (string $key, string $label) use ($base, $qs, $sort, $dir): string {
    $active = $sort === $key;
    // ponowny klik w aktywne sortowanie odwraca kierunek
    $defaultDir = $key === 'time' ? 'asc' : 'desc';
    $nextDir = $active ? ($dir === 'asc' ? 'desc' : 'asc') : $defaultDir;
    $dirLabel = $active ? ($dir === 'asc' ? ' (rosnąco)' : ' (malejąco)') : '';
    return '<a class="rt-seg' . ($active ? ' on' : '') . '" href="' . e($base . $qs(['sort' => $key, 'dir' => $nextDir])) . '">'
        . e($label . $dirLabel) . '</a>';
};
$ratingsOn = !empty($ev['ratings_enabled']);
$openMin = (int)($ev['ratings_open_after_start_min'] ?? Ratings::DEFAULT_OPEN_MIN);
$closeMin = (int)($ev['ratings_close_after_end_min'] ?? Ratings::DEFAULT_CLOSE_MIN);
require APP_DIR . '/views/_head.php';
?>
<div class="panel-top"><div class="wrap">
  <?php require APP_DIR . '/views/_logo.php'; ?>
  <strong style="font-family:Sora,sans-serif;font-size:18px">Eskulapp · Panel</strong>
  <a class="btn btn-ghost" style="margin-left:auto;padding:8px 16px" href="<?= BASE ?>/events/<?= (int)$ev['id'] ?>">Edycja wydarzenia</a>
  <a class="btn btn-ghost" style="padding:8px 16px" href="<?= BASE ?>/dashboard">Wróć</a>
</div></div>

<div class="wrap" style="padding:32px 24px">
  <div style="display:flex;align-items:center;gap:14px;flex-wrap:wrap">
    <div>
      <h1 style="font-size:26px">Oceny prelekcji</h1>
      <div style="color:var(--muted);margin-top:4px"><?= e($ev['name']) ?> <span class="ev-code" style="margin-left:8px"><?= e($ev['access_code']) ?></span></div>
    </div>
    <a class="btn btn-primary" style="margin-left:auto" href="<?= e($base . '.csv' . $qs(['widok' => $tab, 'sort' => $sort, 'dir' => $dir])) ?>">
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 4v11M7 10l5 5 5-5M5 20h14"/></svg>
      Eksport CSV
    </a>
  </div>

  <?php if (!$ratingsOn): ?>
    <div class="msg-err" style="margin-top:18px">Oceny są wyłączone dla tego wydarzenia: aplikacja nie pokazuje sekcji „Oceń wykład”. Włączysz je w edycji wydarzenia.</div>
  <?php endif; ?>

  <div class="rt-tiles">
    <div class="rt-tile"><b><?= (int)$report['total_votes'] ?></b><span>głosów łącznie</span></div>
    <div class="rt-tile"><b><?= (int)$report['voters'] ?></b><span>oceniających urządzeń</span></div>
    <div class="rt-tile"><b><?= (int)$report['rated_talks'] ?> z <?= count($report['talks']) ?></b><span>prelekcji z ocenami</span></div>
    <div class="rt-tile"><b><?= $openMin ?> / <?= $closeMin ?> min</b><span>okno: po starcie / po końcu</span></div>
  </div>
  <p class="rt-note">Skala od 1 do 10, jeden głos na urządzenie (można go zmienić w oknie oceniania). Wyniki widzi tylko panel, uczestnicy nie widzą średnich. Poniżej <?= Ratings::SMALL_SAMPLE ?> głosów wynik oznaczamy jako „mała próba”.</p>

  <div class="rt-tabs">
    <a class="<?= $tab === 'prelekcje' ? 'on' : '' ?>" href="<?= e($base . $qs(['widok' => 'prelekcje', 'sort' => $sort, 'dir' => $dir])) ?>">Prelekcje</a>
    <a class="<?= $tab === 'prelegenci' ? 'on' : '' ?>" href="<?= e($base . $qs(['widok' => 'prelegenci'])) ?>">Ranking prelegentów</a>
  </div>

  <?php if ($tab === 'prelekcje'): ?>
    <div class="rt-sort">
      <span>Sortuj:</span>
      <?= $sortLink('avg', 'Średnia') ?>
      <?= $sortLink('votes', 'Liczba głosów') ?>
      <?= $sortLink('time', 'Kolejność w agendzie') ?>
    </div>
    <?php if (!$report['talks']): ?>
      <div class="panel-card" style="margin-top:16px"><h3>Brak prelekcji</h3><p>To wydarzenie nie ma jeszcze agendy.</p></div>
    <?php else: ?>
      <div class="rt-wrap">
        <table class="rt-table">
          <thead><tr>
            <th>Tytuł</th><th>Prelegenci</th><th>Sala</th><th>Dzień</th>
            <th class="n">Głosy</th><th class="n">Średnia</th><th class="n">Mediana</th><th>Rozkład ocen</th>
          </tr></thead>
          <tbody>
          <?php foreach ($report['talks'] as $r): $s = $r['stats']; $max = max($s['dist']) ?: 1; ?>
            <tr>
              <td class="rt-title"><?= e($r['title']) ?><?php if ($r['time'] !== ''): ?><span><?= e($r['time']) ?></span><?php endif; ?></td>
              <td><?= $r['speakers'] !== '' ? e($r['speakers']) : '<span class="rt-faint">brak</span>' ?></td>
              <td><?= e($r['room'] ?? '') ?></td>
              <td class="rt-nowrap"><?= e($r['day']) ?></td>
              <td class="n"><?= (int)$s['votes'] ?><?php if ($s['votes'] > 0 && $s['small']): ?><span class="rt-small">mała próba</span><?php endif; ?></td>
              <td class="n rt-avg"><?= $s['votes'] > 0 ? e($num($s['avg'])) : '<span class="rt-faint">brak</span>' ?></td>
              <td class="n"><?= $s['votes'] > 0 ? e($num($s['median'])) : '' ?></td>
              <td>
                <div class="rt-hist" role="img" aria-label="Rozkład ocen od 1 do 10">
                  <?php foreach ($s['dist'] as $score => $count): ?>
                    <i title="Ocena <?= (int)$score ?>: <?= (int)$count ?>" style="height:<?= $count > 0 ? max(8, (int)round($count / $max * 100)) : 0 ?>%"></i>
                  <?php endforeach; ?>
                </div>
                <div class="rt-hist-x"><span>1</span><span>10</span></div>
              </td>
            </tr>
          <?php endforeach; ?>
          </tbody>
        </table>
      </div>
    <?php endif; ?>
  <?php else: ?>
    <p class="rt-note" style="margin-top:14px">Średnia ważona liczbą głosów: suma wszystkich ocen z prelekcji danej osoby podzielona przez liczbę tych głosów.</p>
    <?php if (!$report['speakers']): ?>
      <div class="panel-card" style="margin-top:16px"><h3>Brak prelegentów</h3><p>Nie ma prelegentów przypisanych do prelekcji.</p></div>
    <?php else: ?>
      <div class="rt-wrap">
        <table class="rt-table">
          <thead><tr>
            <th class="n">Miejsce</th><th>Prelegent</th><th class="n">Prelekcje</th><th class="n">Głosy</th><th class="n">Średnia ważona</th>
          </tr></thead>
          <tbody>
          <?php foreach ($report['speakers'] as $i => $r): ?>
            <tr>
              <td class="n"><?= $r['votes'] > 0 ? $i + 1 : '' ?></td>
              <td class="rt-title"><?= e($r['name']) ?><?php if (!empty($r['title'])): ?><span><?= e($r['title']) ?></span><?php endif; ?></td>
              <td class="n"><?= (int)$r['talks'] ?></td>
              <td class="n"><?= (int)$r['votes'] ?><?php if ($r['votes'] > 0 && $r['small']): ?><span class="rt-small">mała próba</span><?php endif; ?></td>
              <td class="n rt-avg"><?= $r['votes'] > 0 ? e($num($r['avg'], 2)) : '<span class="rt-faint">brak</span>' ?></td>
            </tr>
          <?php endforeach; ?>
          </tbody>
        </table>
      </div>
    <?php endif; ?>
  <?php endif; ?>
</div>
</body>
</html>
