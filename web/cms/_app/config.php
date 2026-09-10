<?php
declare(strict_types=1);

/**
 * Config + srodowisko Eskulapp CMS (czysty PHP).
 * _app/ jest wspoldzielone przez dyspozytory /panel i /api. Sekrety w _app/.env
 * (poza repo). Kod nieosiagalny z sieci (.htaccess Require all denied w _app/).
 */

const APP_DIR = __DIR__;

function env_load(): array {
    static $cache = null;
    if ($cache !== null) return $cache;
    $vars = [];
    $path = APP_DIR . '/.env';
    if (is_file($path) && is_readable($path)) {
        foreach (file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
            $line = trim($line);
            if ($line === '' || $line[0] === '#' || !str_contains($line, '=')) continue;
            [$k, $v] = explode('=', $line, 2);
            $k = trim($k); $v = trim($v);
            if ((str_starts_with($v, '"') && str_ends_with($v, '"')) ||
                (str_starts_with($v, "'") && str_ends_with($v, "'"))) $v = substr($v, 1, -1);
            $vars[$k] = $v;
        }
    }
    return $cache = $vars;
}

function env(string $key, ?string $default = null): ?string {
    $v = getenv($key);
    if ($v !== false && $v !== '') return $v;
    return env_load()[$key] ?? $default;
}

function db(): ?PDO {
    static $pdo = null, $tried = false;
    if ($tried) return $pdo;
    $tried = true;
    $name = env('DB_NAME'); $user = env('DB_USER');
    if (!$name || !$user) return null;
    $dsn = 'mysql:host=' . env('DB_HOST', 'localhost') . ";dbname={$name};charset=utf8mb4";
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
