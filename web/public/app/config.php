<?php
declare(strict_types=1);

/**
 * Config + środowisko Eskulapp (czysty PHP).
 * Czyta .env z (kolejno): getenv(), potem pliku APP_DIR/.env lub ../.env.
 * Sekrety (DB, JWT) trzymamy POZA webrootem, w katalogu app/ (sibling
 * public_html), nigdy w repo. Bez .env app działa w trybie demo (bez DB).
 */

const APP_DIR = __DIR__;

function env_load(): array {
    static $cache = null;
    if ($cache !== null) return $cache;
    $vars = [];
    foreach ([APP_DIR . '/.env', dirname(APP_DIR) . '/.env'] as $path) {
        if (is_file($path) && is_readable($path)) {
            foreach (file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
                $line = trim($line);
                if ($line === '' || $line[0] === '#') continue;
                if (!str_contains($line, '=')) continue;
                [$k, $v] = explode('=', $line, 2);
                $k = trim($k); $v = trim($v);
                if ((str_starts_with($v, '"') && str_ends_with($v, '"')) ||
                    (str_starts_with($v, "'") && str_ends_with($v, "'"))) {
                    $v = substr($v, 1, -1);
                }
                $vars[$k] = $v;
            }
            break;
        }
    }
    $cache = $vars;
    return $cache;
}

function env(string $key, ?string $default = null): ?string {
    $v = getenv($key);
    if ($v !== false && $v !== '') return $v;
    $vars = env_load();
    return $vars[$key] ?? $default;
}

/** Zwraca PDO albo null, gdy brak konfiguracji DB (tryb demo). */
function db(): ?PDO {
    static $pdo = null;
    static $tried = false;
    if ($tried) return $pdo;
    $tried = true;
    $name = env('DB_NAME'); $user = env('DB_USER');
    if (!$name || !$user) return null;                 // brak DB -> demo
    $host = env('DB_HOST', 'localhost');
    $dsn = "mysql:host={$host};dbname={$name};charset=utf8mb4";
    try {
        $pdo = new PDO($dsn, $user, env('DB_PASS', ''), [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ]);
    } catch (Throwable $e) {
        error_log('Eskulapp DB connect failed: ' . $e->getMessage());
        $pdo = null;
    }
    return $pdo;
}

function config(): array {
    return [
        'app_name' => 'Eskulapp',
        'domain'   => env('DEPLOY_DOMAIN', 'eskulapp.pl'),
        'debug'    => env('APP_DEBUG', '0') === '1',
    ];
}
