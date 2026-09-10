<?php
declare(strict_types=1);

/** Model eventow dla panelu admina (CRUD + kody dostepu). */
final class Events
{
    public static function all(PDO $pdo): array {
        return $pdo->query("SELECT id,name,access_code,status,is_closed,starts_at,ends_at,city,venue_name,slug
                            FROM events ORDER BY COALESCE(starts_at, created_at) DESC")->fetchAll();
    }

    public static function get(PDO $pdo, int $id): ?array {
        $st = $pdo->prepare("SELECT * FROM events WHERE id=? LIMIT 1");
        $st->execute([$id]);
        return $st->fetch() ?: null;
    }

    /** @return array [errors[], id|null] */
    public static function save(PDO $pdo, array $in, ?int $id): array {
        $errors = [];
        $name = trim($in['name'] ?? '');
        if ($name === '') $errors['name'] = 'Podaj nazwę wydarzenia.';

        $code = strtoupper(trim($in['access_code'] ?? ''));
        if ($code === '') $code = self::genCode($name);
        if (!preg_match('/^[A-Z0-9]{3,32}$/', $code)) $errors['access_code'] = 'Kod: 3-32 znaki A-Z i 0-9.';
        elseif (!self::codeUnique($pdo, $code, $id)) $errors['access_code'] = 'Ten kod jest już zajęty.';

        $slug = trim($in['slug'] ?? '');
        if ($slug === '') $slug = self::slugify($name);
        else $slug = self::slugify($slug);
        if (!self::slugUnique($pdo, $slug, $id)) $slug .= '-' . substr((string)time(), -4);

        $status = in_array($in['status'] ?? '', ['draft','published','archived'], true) ? $in['status'] : 'draft';
        $isClosed = !empty($in['is_closed']) ? 1 : 0;
        $starts = self::dt($in['starts_at'] ?? '');
        $ends   = self::dt($in['ends_at'] ?? '');
        $city   = trim($in['city'] ?? '') ?: null;
        $venue  = trim($in['venue_name'] ?? '') ?: null;

        if ($errors) return [$errors, null];

        if ($id) {
            $st = $pdo->prepare("UPDATE events SET name=?,access_code=?,slug=?,status=?,is_closed=?,starts_at=?,ends_at=?,city=?,venue_name=? WHERE id=?");
            $st->execute([$name,$code,$slug,$status,$isClosed,$starts,$ends,$city,$venue,$id]);
            return [[], $id];
        }
        $st = $pdo->prepare("INSERT INTO events (name,access_code,slug,status,is_closed,starts_at,ends_at,city,venue_name,push_topic)
                             VALUES (?,?,?,?,?,?,?,?,?,'')");
        $st->execute([$name,$code,$slug,$status,$isClosed,$starts,$ends,$city,$venue]);
        $newId = (int)$pdo->lastInsertId();
        $pdo->prepare("UPDATE events SET push_topic=? WHERE id=?")->execute(['event_' . $newId, $newId]);
        return [[], $newId];
    }

    public static function delete(PDO $pdo, int $id): void {
        $pdo->prepare("DELETE FROM events WHERE id=?")->execute([$id]);
    }

    public static function codeUnique(PDO $pdo, string $code, ?int $exceptId): bool {
        $st = $pdo->prepare("SELECT id FROM events WHERE access_code=? AND (? IS NULL OR id<>?) LIMIT 1");
        $st->execute([$code, $exceptId, $exceptId]);
        return !$st->fetch();
    }
    public static function slugUnique(PDO $pdo, string $slug, ?int $exceptId): bool {
        $st = $pdo->prepare("SELECT id FROM events WHERE slug=? AND (? IS NULL OR id<>?) LIMIT 1");
        $st->execute([$slug, $exceptId, $exceptId]);
        return !$st->fetch();
    }

    /** Kod: inicjaly z nazwy + rok (lub losowy dopelniacz). */
    public static function genCode(string $name): string {
        $letters = strtoupper(preg_replace('/[^A-Za-z]/', '', self::ascii($name)));
        $ini = '';
        foreach (preg_split('/\s+/', trim(self::ascii($name))) as $w) {
            if ($w !== '' && ctype_alpha($w[0])) $ini .= strtoupper($w[0]);
            if (strlen($ini) >= 3) break;
        }
        if (strlen($ini) < 2) $ini = substr($letters . 'EV', 0, 3);
        $year = preg_match('/(20\d{2})/', $name, $m) ? $m[1] : date('Y');
        return substr($ini, 0, 4) . $year;
    }

    public static function slugify(string $s): string {
        $s = strtolower(self::ascii($s));
        $s = preg_replace('/[^a-z0-9]+/', '-', $s);
        return trim($s, '-') ?: 'event';
    }

    private static function ascii(string $s): string {
        $map = ['ą'=>'a','ć'=>'c','ę'=>'e','ł'=>'l','ń'=>'n','ó'=>'o','ś'=>'s','ż'=>'z','ź'=>'z',
                'Ą'=>'A','Ć'=>'C','Ę'=>'E','Ł'=>'L','Ń'=>'N','Ó'=>'O','Ś'=>'S','Ż'=>'Z','Ź'=>'Z'];
        return strtr($s, $map);
    }

    /** datetime-local (YYYY-MM-DDTHH:MM) -> MySQL DATETIME lub null. */
    private static function dt(string $v): ?string {
        $v = trim($v);
        if ($v === '') return null;
        $v = str_replace('T', ' ', $v);
        if (preg_match('/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$/', $v)) return $v . ':00';
        if (preg_match('/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/', $v)) return $v;
        return null;
    }
}
