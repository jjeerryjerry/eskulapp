<?php
declare(strict_types=1);

/**
 * Wspolny router Eskulapp. Dyspozytor (panel/api index.php) definiuje BASE
 * ('/panel' albo '/api') i wola ten plik.
 *
 * /api:    GET  /public/events/{code}/bundle | GET /health | POST /lead
 *          POST /public/events/{code}/talks/{talkId}/rating      (oceny, SPEC-OCENY §4)
 *          GET  /public/events/{code}/ratings/mine?install_id=...
 * /panel:  panel ADMINA (event dodaje admin/agent, nie organizator).
 *          GET / , GET /logowanie , POST /logowanie , GET /dashboard , GET /wyloguj
 *          GET /events/{id}/oceny[.csv]?widok=prelekcje|prelegenci  (wyniki ocen)
 */

require __DIR__ . '/config.php';
require __DIR__ . '/security.php';
require __DIR__ . '/lib/Bundle.php';
require __DIR__ . '/lib/Events.php';
require __DIR__ . '/lib/Ratings.php';

if (!defined('BASE')) define('BASE', '');
define('ASSET_BASE', BASE . '/assets');

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
$path   = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?? '/';
// odetnij BASE z URI
if (BASE !== '' && str_starts_with($path, BASE)) $path = substr($path, strlen(BASE));
$path = '/' . ltrim($path, '/');
$path = rtrim($path, '/') ?: '/';

function view(string $name, array $data = []): void {
    security_headers(true);
    extract($data, EXTR_SKIP);
    require APP_DIR . '/views/' . $name . '.php';
}
function json_out($data, int $status = 200, bool $cors = true): void {
    security_headers(false);
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    if ($cors) header('Access-Control-Allow-Origin: *');
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}
/**
 * Wspolna obsluga API ocen: bez CORS (klient to apka natywna), bez cache,
 * wymagane DB i RATING_SALT (bez soli nie hashujemy install_id, fail closed).
 * $fn(PDO, salt) zwraca [status HTTP, cialo].
 */
function ratings_api(callable $fn): void {
    header('Cache-Control: no-store');
    $pdo = db();
    $salt = (string)env('RATING_SALT', '');
    if ($pdo === null || strlen($salt) < 16) {
        error_log('Eskulapp ratings: brak DB albo RATING_SALT (min. 16 znakow) w _app/.env');
        json_out(['error' => 'unavailable'], 503, false);
    }
    try {
        [$status, $body] = $fn($pdo, $salt);
    } catch (Throwable $e) {
        error_log('Eskulapp ratings: ' . $e->getMessage());
        json_out(['error' => 'server_error'], 500, false);
    }
    if ($status === 429) header('Retry-After: 60');
    json_out($body, $status, false);
}
/** CSV dla Excela PL: UTF-8 z BOM, separator ';', CRLF. */
function csv_out(string $filename, array $rows): void {
    security_headers(false);
    header('Content-Type: text/csv; charset=utf-8');
    header('Content-Disposition: attachment; filename="' . $filename . '"');
    header('Cache-Control: no-store');
    $out = fopen('php://output', 'w');
    fwrite($out, "\xEF\xBB\xBF");
    foreach ($rows as $r) fputcsv($out, $r, ';', '"', '', "\r\n");
    fclose($out);
    exit;
}
function e(?string $s): string { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }

// ============================ API ============================
if (BASE === '/api') {
    if (preg_match('#^/public/events/([A-Za-z0-9_-]{1,32})/bundle$#', $path, $m)) {
        $b = Bundle::forCode($m[1]);
        if ($b === null) json_out(['error' => 'not_found', 'code' => strtoupper($m[1])], 404);
        json_out($b);
    }
    // Oceny prelekcji (SPEC-OCENY §4). Zapis idzie tu, nie na CDN.
    if (preg_match('#^/public/events/([A-Za-z0-9_-]{1,32})/talks/(\d{1,18})/rating$#', $path, $m)) {
        if ($method !== 'POST') { header('Allow: POST'); json_out(['error' => 'method_not_allowed'], 405, false); }
        ratings_api(fn(PDO $pdo, string $salt) => Ratings::submit(
            $pdo, $m[1], (int)$m[2], Ratings::readJsonBody(), client_ip(), $salt, Ratings::now()));
    }
    if (preg_match('#^/public/events/([A-Za-z0-9_-]{1,32})/ratings/mine$#', $path, $m)) {
        if ($method !== 'GET') { header('Allow: GET'); json_out(['error' => 'method_not_allowed'], 405, false); }
        ratings_api(fn(PDO $pdo, string $salt) => Ratings::mine(
            $pdo, $m[1], $_GET['install_id'] ?? null, client_ip(), $salt, Ratings::now()));
    }
    if ($path === '/health') {
        json_out(['ok' => true, 'service' => 'eskulapp-api', 'db' => db() !== null, 'ts' => gmdate('c')]);
    }
    if ($path === '/lead' && $method === 'POST') {
        $l = [
            'name'    => trim($_POST['name'] ?? ''),
            'email'   => trim($_POST['email'] ?? ''),
            'org'     => trim($_POST['org'] ?? ''),
            'message' => trim($_POST['message'] ?? ''),
        ];
        $err = [];
        if ($l['name'] === '') $err[] = 'name';
        if (!filter_var($l['email'], FILTER_VALIDATE_EMAIL)) $err[] = 'email';
        // honeypot (pole 'website' powinno byc puste)
        if (trim($_POST['website'] ?? '') !== '') json_out(['ok' => true]); // bot -> udawaj sukces
        if ($err) json_out(['ok' => false, 'errors' => $err], 422);
        $pdo = db();
        if ($pdo) {
            $pdo->prepare('INSERT INTO leads (name,email,org,message,ip) VALUES (?,?,?,?,?)')
                ->execute([$l['name'], $l['email'], $l['org'], $l['message'], client_ip()]);
        }
        lead_mail($l);   // zawsze wyslij na kontakt@eskulapp.pl
        json_out(['ok' => true]);
    }
    json_out(['error' => 'not_found'], 404);
}

// ============================ PANEL (admin) ============================
session_boot();

if ($path === '/wyloguj') {
    $_SESSION = []; session_destroy();
    header('Location: ' . BASE . '/logowanie'); exit;
}

$logged = !empty($_SESSION['admin_id']);

if ($path === '/logowanie' || $path === '/') {
    if ($logged && $path === '/') { header('Location: ' . BASE . '/dashboard'); exit; }
    if ($method === 'POST') {
        if (!csrf_check()) { view('logowanie', ['error' => 'Sesja wygasla, sprobuj ponownie.']); exit; }
        $email = trim($_POST['email'] ?? '');
        $pass  = (string)($_POST['password'] ?? '');
        $pdo = db();
        if ($pdo === null) { view('logowanie', ['notice' => 'Brak polaczenia z baza. Sprobuj pozniej.']); exit; }
        $rl = $pdo->prepare("SELECT COUNT(*) FROM login_attempts WHERE email=? AND ok=0 AND created_at > (NOW() - INTERVAL 15 MINUTE)");
        $rl->execute([$email]);
        if ((int)$rl->fetchColumn() >= 8) { view('logowanie', ['error' => 'Za duzo prob. Odczekaj kilka minut.']); exit; }
        $st = $pdo->prepare("SELECT id,password_hash,name,role FROM organizers WHERE email=? LIMIT 1");
        $st->execute([$email]);
        $u = $st->fetch();
        $ok = $u && password_verify($pass, $u['password_hash']);
        $pdo->prepare("INSERT INTO login_attempts (email,ip,ok) VALUES (?,?,?)")->execute([$email, client_ip(), $ok ? 1 : 0]);
        if ($ok) {
            session_regenerate_id(true);
            $_SESSION['admin_id'] = (int)$u['id'];
            $_SESSION['admin_name'] = $u['name'];
            $_SESSION['admin_role'] = $u['role'];
            $_SESSION['_born'] = time();
            header('Location: ' . BASE . '/dashboard'); exit;
        }
        view('logowanie', ['error' => 'Nieprawidlowy e-mail lub haslo.']); exit;
    }
    view('logowanie', ['csrf' => csrf_token()]); exit;
}

// dalej tylko po zalogowaniu
if (!$logged) { header('Location: ' . BASE . '/logowanie'); exit; }
$pdo = db();

if (($path === '/dashboard' || $path === '/events') && $method === 'GET') {
    $events = $pdo ? Events::all($pdo) : [];
    view('dashboard', ['name' => $_SESSION['admin_name'] ?? 'Admin', 'events' => $events]);
    exit;
}

// nowy event
if ($path === '/events/new' && $method === 'GET') {
    view('event_form', ['isNew' => true, 'ev' => [], 'csrf' => csrf_token()]);
    exit;
}

// utworzenie
if ($path === '/events' && $method === 'POST') {
    if (!csrf_check() || !$pdo) { header('Location: ' . BASE . '/events/new'); exit; }
    [$errors, $newId] = Events::save($pdo, $_POST, null);
    if ($errors) { view('event_form', ['isNew' => true, 'ev' => $_POST, 'errors' => $errors, 'csrf' => csrf_token()]); exit; }
    header('Location: ' . BASE . '/dashboard'); exit;
}

// oceny prelekcji: tabela prelekcji, ranking prelegentow, eksport CSV (tylko odczyt)
if (preg_match('#^/events/(\d+)/oceny(\.csv)?$#', $path, $m) && $method === 'GET') {
    $ev = $pdo ? Events::get($pdo, (int)$m[1]) : null;
    if (!$ev) { http_response_code(404); view('404', []); exit; }
    $tab = ($_GET['widok'] ?? '') === 'prelegenci' ? 'prelegenci' : 'prelekcje';
    $sort = in_array($_GET['sort'] ?? '', ['avg', 'votes', 'time'], true) ? $_GET['sort'] : 'avg';
    $dirIn = $_GET['dir'] ?? '';
    $dir = in_array($dirIn, ['asc', 'desc'], true) ? $dirIn : ($sort === 'time' ? 'asc' : 'desc');
    $report = Ratings::report($pdo, (int)$ev['id']);
    $report['talks'] = Ratings::sortTalks($report['talks'], $sort, $dir);
    if (!empty($m[2])) {
        $code = preg_replace('/[^A-Z0-9]/', '', strtoupper((string)$ev['access_code'])) ?: 'EVENT';
        csv_out("oceny-{$code}-{$tab}.csv",
            $tab === 'prelegenci' ? Ratings::csvSpeakers($report['speakers']) : Ratings::csvTalks($report['talks']));
    }
    view('ratings', ['ev' => $ev, 'report' => $report, 'tab' => $tab, 'sort' => $sort, 'dir' => $dir]);
    exit;
}

// edycja / update / delete po id
if (preg_match('#^/events/(\d+)(/delete)?$#', $path, $m)) {
    $id = (int)$m[1];
    $isDelete = !empty($m[2]);
    if ($method === 'POST' && $isDelete) {
        if (csrf_check() && $pdo) Events::delete($pdo, $id);
        header('Location: ' . BASE . '/dashboard'); exit;
    }
    if ($method === 'POST') {
        if (!csrf_check() || !$pdo) { header('Location: ' . BASE . '/events/' . $id); exit; }
        [$errors, ] = Events::save($pdo, $_POST, $id);
        if ($errors) {
            $ev = $_POST; $ev['id'] = $id;
            view('event_form', ['isNew' => false, 'ev' => $ev, 'errors' => $errors, 'csrf' => csrf_token()]); exit;
        }
        header('Location: ' . BASE . '/dashboard'); exit;
    }
    // GET -> formularz edycji
    $ev = $pdo ? Events::get($pdo, $id) : null;
    if (!$ev) { http_response_code(404); view('404', []); exit; }
    view('event_form', ['isNew' => false, 'ev' => $ev, 'csrf' => csrf_token()]);
    exit;
}

http_response_code(404);
view('404', []);
