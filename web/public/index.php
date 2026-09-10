<?php
declare(strict_types=1);

/**
 * Eskulapp, front controller (czysty PHP).
 * Docroot = public_html (ten katalog). Kod aplikacji i sekrety: ../app (poza webrootem).
 * Trasy:
 *   GET  /                                  -> landing (V3 Identyfikator)
 *   GET  /logowanie                         -> panel organizatora (logowanie)
 *   POST /logowanie                         -> obsługa logowania
 *   POST /kontakt                           -> lead z formularza dla organizatora
 *   GET  /api/public/events/{code}/bundle   -> publiczny bundle eventu (app)
 *   GET  /health                            -> status JSON
 */

// app/ leży WEWNĄTRZ webroota (hosting cyber-folks ma open_basedir = public_html),
// dostęp z sieci do /app zablokowany w .htaccess.
$appDir = __DIR__ . '/app';
require $appDir . '/config.php';
require APP_DIR . '/lib/Bundle.php';

$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
$uri    = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?? '/';
$uri    = rtrim($uri, '/') ?: '/';

function view(string $name, array $data = []): void {
    extract($data, EXTR_SKIP);
    require APP_DIR . '/views/' . $name . '.php';
}
function json_out($data, int $status = 200): void {
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    header('Access-Control-Allow-Origin: *');           // publiczny read-only
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}
function e(?string $s): string { return htmlspecialchars((string)$s, ENT_QUOTES, 'UTF-8'); }

//  API: publiczny bundle eventu 
if (preg_match('#^/api/public/events/([A-Za-z0-9_-]{1,32})/bundle$#', $uri, $m)) {
    $bundle = Bundle::forCode($m[1]);
    if ($bundle === null) json_out(['error' => 'not_found', 'code' => strtoupper($m[1])], 404);
    // delta ?since= (ISO), na razie zwracamy pełny, ale pole updated_at już jest
    json_out($bundle);
}

if ($uri === '/health') {
    json_out(['ok' => true, 'service' => 'eskulapp-web', 'db' => db() !== null, 'ts' => gmdate('c')]);
}

//  POST /kontakt, lead „dla organizatora" 
if ($uri === '/kontakt' && $method === 'POST') {
    $name  = trim($_POST['name'] ?? '');
    $email = trim($_POST['email'] ?? '');
    $org   = trim($_POST['org'] ?? '');
    $msg   = trim($_POST['message'] ?? '');
    $hint  = trim($_POST['event_hint'] ?? '');
    $errors = [];
    if ($name === '') $errors[] = 'Podaj imię i nazwisko.';
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) $errors[] = 'Podaj poprawny e-mail.';
    if (!$errors) {
        $pdo = db();
        if ($pdo !== null) {
            $st = $pdo->prepare("INSERT INTO leads (name,email,org,message,event_hint,ip) VALUES (?,?,?,?,?,?)");
            $st->execute([$name, $email, $org, $msg, $hint, $_SERVER['REMOTE_ADDR'] ?? null]);
        } else {
            // fallback bez DB: nie gubimy leada, dopisujemy do pliku poza webrootem
            $line = json_encode(compact('name','email','org','msg','hint') + ['ts' => gmdate('c')], JSON_UNESCAPED_UNICODE);
            @file_put_contents(APP_DIR . '/leads.log', $line . "\n", FILE_APPEND | LOCK_EX);
        }
        view('landing', ['sent' => true]);
        exit;
    }
    view('landing', ['errors' => $errors, 'old' => compact('name','email','org','msg','hint')]);
    exit;
}

//  /logowanie, panel organizatora 
if ($uri === '/logowanie') {
    if ($method === 'POST') {
        $email = trim($_POST['email'] ?? '');
        $pass  = (string)($_POST['password'] ?? '');
        $pdo = db();
        if ($pdo === null) {
            view('logowanie', ['notice' => 'Panel organizatora będzie dostępny po podpięciu bazy danych. Wróć wkrótce.']);
            exit;
        }
        // rate-limit: max 8 nieudanych / 15 min per email
        $rl = $pdo->prepare("SELECT COUNT(*) FROM login_attempts WHERE email=? AND ok=0 AND created_at > (NOW() - INTERVAL 15 MINUTE)");
        $rl->execute([$email]);
        if ((int)$rl->fetchColumn() >= 8) {
            view('logowanie', ['error' => 'Za dużo prób. Spróbuj za kilka minut.']);
            exit;
        }
        $st = $pdo->prepare("SELECT id,password_hash,name FROM organizers WHERE email=? LIMIT 1");
        $st->execute([$email]);
        $u = $st->fetch();
        $ok = $u && password_verify($pass, $u['password_hash']);
        $pdo->prepare("INSERT INTO login_attempts (email,ip,ok) VALUES (?,?,?)")
            ->execute([$email, $_SERVER['REMOTE_ADDR'] ?? '', $ok ? 1 : 0]);
        if ($ok) {
            session_start();
            session_regenerate_id(true);
            $_SESSION['org_id'] = (int)$u['id'];
            $_SESSION['org_name'] = $u['name'];
            header('Location: /panel');
            exit;
        }
        view('logowanie', ['error' => 'Nieprawidłowy e-mail lub hasło.']);
        exit;
    }
    view('logowanie', []);
    exit;
}

//  /panel, CMS (szkielet, wymaga sesji) 
if ($uri === '/panel') {
    session_start();
    if (empty($_SESSION['org_id'])) { header('Location: /logowanie'); exit; }
    view('panel', ['name' => $_SESSION['org_name'] ?? 'Organizator']);
    exit;
}
if ($uri === '/wyloguj') {
    session_start(); $_SESSION = []; session_destroy();
    header('Location: /logowanie'); exit;
}

//  /, landing 
if ($uri === '/') { view('landing', []); exit; }

// 404
http_response_code(404);
view('404', []);
