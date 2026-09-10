<?php
/** @var bool $sent @var array $errors @var array $old */
$sent   = $sent   ?? false;
$errors = $errors ?? [];
$old    = $old    ?? [];
$title  = null;
require APP_DIR . '/views/_head.php';
?>
<nav class="nav"><div class="wrap nav-inner">
  <a class="nav-brand" href="/"><?php require APP_DIR . '/views/_logo.php'; ?>Eskulapp</a>
  <div class="nav-links">
    <a href="#funkcje">Funkcje</a>
    <a href="#organizator">Dla organizatora</a>
    <a href="#pobierz">Pobierz</a>
    <a class="btn btn-primary" href="/logowanie">Panel organizatora</a>
  </div>
</div></nav>

<header class="wrap hero">
  <div>
    <span class="eyebrow">Twój identyfikator na każdy event</span>
    <h1>Jeden kod, cały<br>event <span>w telefonie</span>.</h1>
    <p class="lead">Dołącz do konferencji medycznej jednym kodem, bez zakładania konta. Agenda, prelegenci, partnerzy, mapa stoisk i przypomnienia o prelekcjach masz zawsze przy sobie, także offline.</p>
    <div class="hero-cta">
      <a class="btn btn-primary" href="#pobierz">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3v12M7 10l5 5 5-5M5 21h14"/></svg>
        Pobierz aplikację
      </a>
      <a class="btn btn-ghost" href="#funkcje">Zobacz jak działa</a>
    </div>
  </div>
  <div class="badge-col">
    <div class="lanyard"></div><div class="lanyard-ring"></div>
    <div class="badge">
      <div class="badge-top">
        <span class="seal"><svg width="18" viewBox="0 0 40 48" fill="none"><rect x="9" y="7" width="6" height="34" rx="3" fill="#0C5A63"/><path d="M31 9 L18 9 L18 39 L31 39" stroke="#FF6B57" stroke-width="6" fill="none" stroke-linecap="round" stroke-linejoin="round"/><path d="M18 24 L28 24" stroke="#FF6B57" stroke-width="6" fill="none" stroke-linecap="round"/><circle cx="31" cy="9" r="3.2" fill="#FF6B57"/></svg></span>
        <b>UCZESTNIK</b>
      </div>
      <div class="badge-body">
        <div class="badge-ava">AK</div>
        <div class="badge-name">dr Anna Kowalska</div>
        <div class="badge-role">Nefrologia · Warszawa</div>
        <div class="badge-code">
          <div><div class="lbl">KOD EVENTU</div><div class="val">FND2027</div></div>
          <div class="qr">
            <span class="on"></span><span></span><span class="on"></span><span class="on"></span>
            <span></span><span class="on"></span><span></span><span class="on"></span>
            <span class="on"></span><span></span><span class="on"></span><span></span>
            <span class="on"></span><span class="on"></span><span></span><span class="on"></span>
          </div>
        </div>
      </div>
    </div>
  </div>
</header>

<section class="section" id="funkcje"><div class="wrap">
  <h2>Wszystko o wydarzeniu, w jednym miejscu</h2>
  <p class="sub">Program jak z wydruku, tylko żywy: zmiany sal i prelegentów widzisz od razu, a apka przypomni o tym, co ważne.</p>
  <div class="features">
    <div class="feat">
      <div class="ic"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#0C5A63" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="17" rx="2"/><path d="M3 9h18M8 2v4M16 2v4"/></svg></div>
      <h3>Agenda</h3><p>Dni, sale i filtr prelekcji. Wszystko czytelnie na telefonie.</p>
    </div>
    <div class="feat">
      <div class="ic"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#0C5A63" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><path d="M6 9a6 6 0 1 1 12 0c0 5 2 6 2 6H4s2-1 2-6z"/><path d="M10 20a2 2 0 0 0 4 0"/></svg></div>
      <h3>Przypomnienia</h3><p>Ustaw prelekcję, a apka przypomni, nie przegapisz.</p>
    </div>
    <div class="feat">
      <div class="ic"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#0C5A63" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.5 10 17l9-10"/></svg></div>
      <h3>Offline</h3><p>Cały program masz zapisany, działa bez zasięgu w hali.</p>
    </div>
    <div class="feat accent">
      <div class="ic"><svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#FF6B57" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><path d="M12 5v14M5 12h14"/></svg></div>
      <h3>Kolejny event</h3><p>Dodajesz następne wydarzenie jednym kodem dostępu.</p>
    </div>
  </div>

  <div style="display:grid;grid-template-columns:1fr;gap:14px;margin-top:34px">
    <h3 style="font-size:19px">Program dnia, na żywo</h3>
    <div class="prog-list">
      <div class="prog"><span class="t">09:00-09:45</span><div><div class="nm">Sesja otwierająca</div><div class="rm">Sala A · prof. Nowak</div></div></div>
      <div class="prog"><span class="t">10:00-10:45</span><div><div class="nm">Nowe wytyczne leczenia 2027</div><div class="rm">Sala A · prof. Kowalska</div></div><span class="live">NA ŻYWO</span></div>
      <div class="prog" style="opacity:.6"><span class="t">11:00-12:30</span><div><div class="nm">Warsztat USG nerek</div><div class="rm">Sala C · dr Wiśniewski</div></div></div>
    </div>
  </div>
</div></section>

<section class="section" id="pobierz"><div class="wrap" style="text-align:center">
  <h2>Pobierz aplikację</h2>
  <p class="sub" style="margin:10px auto 24px">Android już wkrótce w Google Play. Wersja iOS w planach.</p>
  <div class="hero-cta" style="justify-content:center">
    <a class="btn btn-primary" href="#" aria-disabled="true">Google Play, wkrótce</a>
    <a class="btn btn-ghost" href="#kontakt">Chcę wersję testową</a>
  </div>
</div></section>

<section class="section" id="organizator"><div class="wrap">
  <div class="org" id="kontakt">
    <div>
      <h2>Organizujesz event medyczny?</h2>
      <p>Wydaj uczestnikom cyfrowy identyfikator i zarządzaj programem z panelu, agenda, prelegenci, partnerzy, mapa, aktualności i powiadomienia push.</p>
      <ul>
        <li><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#FF6B57" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg> Kod dostępu do zamkniętego wydarzenia</li>
        <li><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#FF6B57" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg> Zmiany w agendzie widoczne u uczestników od razu</li>
        <li><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#FF6B57" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg> Zaplanowane powiadomienia push (promo/zmiany)</li>
      </ul>
    </div>
    <div class="form">
      <?php if ($sent): ?>
        <h3>Dziękujemy!</h3>
        <div class="msg-ok">Zgłoszenie przyjęte, odezwiemy się na podany e-mail.</div>
      <?php else: ?>
        <h3>Zgłoś swój event</h3>
        <div class="fsub">Zostaw kontakt, pokażemy panel i pomożemy wystartować.</div>
        <?php if ($errors): ?><div class="msg-err"><ul><?php foreach ($errors as $er) echo '<li>' . e($er) . '</li>'; ?></ul></div><?php endif; ?>
        <form method="post" action="/kontakt">
          <div class="field"><label>Imię i nazwisko</label><input name="name" required value="<?= e($old['name'] ?? '') ?>"></div>
          <div class="field"><label>E-mail</label><input type="email" name="email" required value="<?= e($old['email'] ?? '') ?>"></div>
          <div class="field"><label>Organizacja (opcjonalnie)</label><input name="org" value="<?= e($old['org'] ?? '') ?>"></div>
          <div class="field"><label>Wiadomość (opcjonalnie)</label><textarea name="message"><?= e($old['msg'] ?? '') ?></textarea></div>
          <button class="btn btn-primary" type="submit">Wyślij zgłoszenie</button>
        </form>
      <?php endif; ?>
    </div>
  </div>
</div></section>

<?php require APP_DIR . '/views/_foot.php';
