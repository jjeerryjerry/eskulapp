<?php
declare(strict_types=1);

/**
 * Utwardzenie dedykowanego CMS: sesje, naglowki bezpieczenstwa, CSRF.
 * Wolane raz z dyspozytora (panel/api index.php) przez router.
 */

const LEAD_EMAIL = 'kontakt@eskulapp.pl';   // adresat zgloszen z formularza

function security_headers(bool $html): void {
    header('X-Content-Type-Options: nosniff');
    header('Referrer-Policy: strict-origin-when-cross-origin');
    header('X-Frame-Options: DENY');
    header_remove('X-Powered-By');
    if (($_SERVER['HTTPS'] ?? '') === 'on' || ($_SERVER['HTTP_X_FORWARDED_PROTO'] ?? '') === 'https') {
        header('Strict-Transport-Security: max-age=31536000; includeSubDomains');
    }
    if ($html) {
        // CMS nie laduje zasobow zewnetrznych poza Google Fonts
        header("Content-Security-Policy: default-src 'self'; "
            . "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; "
            . "font-src https://fonts.gstatic.com; img-src 'self' data:; "
            . "script-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'");
    }
}

function session_boot(): void {
    if (session_status() === PHP_SESSION_ACTIVE) return;
    $https = (($_SERVER['HTTPS'] ?? '') === 'on') || (($_SERVER['HTTP_X_FORWARDED_PROTO'] ?? '') === 'https');
    session_name('eskcms');
    session_set_cookie_params([
        'lifetime' => 0, 'path' => '/panel', 'secure' => $https,
        'httponly' => true, 'samesite' => 'Lax',
    ]);
    session_start();
    if (empty($_SESSION['_born'])) { $_SESSION['_born'] = time(); }
    // rotacja id co 30 min
    if (time() - ($_SESSION['_born']) > 1800) { session_regenerate_id(true); $_SESSION['_born'] = time(); }
}

function csrf_token(): string {
    if (empty($_SESSION['csrf'])) $_SESSION['csrf'] = bin2hex(random_bytes(32));
    return $_SESSION['csrf'];
}
function csrf_check(): bool {
    $t = $_POST['_csrf'] ?? '';
    return is_string($t) && !empty($_SESSION['csrf']) && hash_equals($_SESSION['csrf'], $t);
}

function client_ip(): string {
    return $_SERVER['REMOTE_ADDR'] ?? '';
}

/** Wyslij lead na skrzynke kontaktowa (mail() lokalnego MTA cyber-folks). */
function lead_mail(array $l): bool {
    $to = LEAD_EMAIL;
    $subject = '=?UTF-8?B?' . base64_encode('Eskulapp: nowe zgloszenie od ' . ($l['name'] ?? '')) . '?=';
    $body = "Nowe zgloszenie z formularza eskulapp.pl\n\n"
        . 'Imie i nazwisko: ' . ($l['name'] ?? '') . "\n"
        . 'E-mail: ' . ($l['email'] ?? '') . "\n"
        . 'Organizacja: ' . ($l['org'] ?? '') . "\n"
        . 'Wiadomosc: ' . ($l['message'] ?? '') . "\n\n"
        . 'IP: ' . client_ip() . "\n"
        . 'Data: ' . gmdate('c') . "\n";
    $headers = "From: Eskulapp <kontakt@eskulapp.pl>\r\n";
    if (filter_var($l['email'] ?? '', FILTER_VALIDATE_EMAIL)) {
        $headers .= 'Reply-To: ' . $l['email'] . "\r\n";
    }
    $headers .= "Content-Type: text/plain; charset=UTF-8\r\n";
    return @mail($to, $subject, $body, $headers, '-f kontakt@eskulapp.pl');
}
