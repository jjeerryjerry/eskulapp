<?php
declare(strict_types=1);

/**
 * Opcjonalna grafika naglowka eventu (NOTATKA-AGENCJA-2026-10-14): organizator wgrywa
 * obraz w CMS, apka pokazuje go zamiast domyslnego petrolowego naglowka.
 *
 * Plik ląduje w <docroot>/media/events/<id>/header-<losowe>.<ext> (losowa nazwa = nowy URL
 * przy kazdej podmianie, wiec apki i CDN nie trzymaja starej wersji). Rozszerzenie
 * nadajemy sami z wykrytego typu, nigdy z nazwy od uzytkownika.
 */
final class EventHeader
{
    public const MAX_BYTES = 3 * 1024 * 1024;
    public const MIN_WIDTH = 600;
    private const TYPES = ['image/jpeg' => 'jpg', 'image/png' => 'png', 'image/webp' => 'webp'];

    /**
     * Obsluga pol formularza: header_image (plik) i header_remove (checkbox).
     * @return ?string blad dla uzytkownika albo null gdy OK / brak zmian
     */
    public static function handle(PDO $pdo, int $eventId, ?array $file, bool $remove): ?string
    {
        $current = self::current($pdo, $eventId);
        $hasFile = $file !== null && ($file['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_NO_FILE;
        if (!$hasFile) {
            if ($remove && $current !== null) {
                self::set($pdo, $eventId, null);
                self::deleteFile($current);
            }
            return null;
        }
        if (($file['error'] ?? -1) !== UPLOAD_ERR_OK) {
            return in_array($file['error'], [UPLOAD_ERR_INI_SIZE, UPLOAD_ERR_FORM_SIZE], true)
                ? 'Plik jest za duży (maks. 3 MB).' : 'Nie udało się wgrać pliku. Spróbuj ponownie.';
        }
        $tmp = (string)$file['tmp_name'];
        if (!is_uploaded_file($tmp)) return 'Nie udało się wgrać pliku. Spróbuj ponownie.';
        if (filesize($tmp) > self::MAX_BYTES) return 'Plik jest za duży (maks. 3 MB).';
        $mime = (new finfo(FILEINFO_MIME_TYPE))->file($tmp) ?: '';
        $ext = self::TYPES[$mime] ?? null;
        $size = @getimagesize($tmp);
        if ($ext === null || $size === false) return 'Dozwolone formaty: JPG, PNG, WebP.';
        if ($size[0] < self::MIN_WIDTH) return 'Grafika jest za mała: minimum ' . self::MIN_WIDTH . ' px szerokości (zalecane 1200 x 500 px).';

        $dir = self::dir($eventId);
        if (!is_dir($dir) && !mkdir($dir, 0755, true)) return 'Błąd zapisu na serwerze.';
        $name = 'header-' . bin2hex(random_bytes(8)) . '.' . $ext;
        if (!move_uploaded_file($tmp, $dir . '/' . $name)) return 'Błąd zapisu na serwerze.';
        @chmod($dir . '/' . $name, 0644);
        self::set($pdo, $eventId, self::baseUrl() . '/media/events/' . $eventId . '/' . $name);
        if ($current !== null) self::deleteFile($current);
        return null;
    }

    private static function current(PDO $pdo, int $eventId): ?string
    {
        $st = $pdo->prepare('SELECT header_image_url FROM events WHERE id = ?');
        $st->execute([$eventId]);
        $v = $st->fetchColumn();
        return is_string($v) && $v !== '' ? $v : null;
    }

    private static function set(PDO $pdo, int $eventId, ?string $url): void
    {
        $pdo->prepare('UPDATE events SET header_image_url = ? WHERE id = ?')->execute([$url, $eventId]);
    }

    private static function dir(int $eventId): string
    {
        return dirname(APP_DIR) . '/media/events/' . $eventId;
    }

    /** Kasuje tylko nasze pliki (header-*.ext w katalogu media), nigdy dowolna sciezke z URL. */
    private static function deleteFile(string $url): void
    {
        if (!preg_match('#/media/events/(\d+)/(header-[0-9a-f]{16}\.(?:jpg|png|webp))$#', $url, $m)) return;
        $path = self::dir((int)$m[1]) . '/' . $m[2];
        if (is_file($path)) @unlink($path);
    }

    private static function baseUrl(): string
    {
        $v = function_exists('env') ? env('PUBLIC_BASE_URL') : null;
        return rtrim(is_string($v) && $v !== '' ? $v : 'https://eskulapp.pl', '/');
    }
}
