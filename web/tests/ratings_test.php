<?php
declare(strict_types=1);

/**
 * Testy modulu ocen (docs/SPEC-OCENY.md §7). Bez composera:
 *
 *   php web/tests/ratings_test.php
 *
 * Czesc czysta (okno czasu, strefa, walidacja, statystyki, CSV) idzie zawsze.
 * Czesc z baza (migracja, upsert, wylaczone oceny, talk z innego eventu, rate-limit,
 * /ratings/mine, raport CMS) wymaga PUSTEJ bazy testowej MySQL/MariaDB, ktorej
 * nazwa zawiera "test" (test zmienia w niej schemat):
 *
 *   ESK_TEST_DB_DSN='mysql:host=127.0.0.1;dbname=esk_test;charset=utf8mb4' \
 *   ESK_TEST_DB_USER=esk ESK_TEST_DB_PASS=... php web/tests/ratings_test.php
 *
 * Bez ESK_TEST_DB_DSN testy DB sa pomijane (SKIP). Kod wyjscia != 0 przy bledzie.
 */

// Celowo obca strefa domyslna: logika ocen NIE moze od niej zalezec (§2).
date_default_timezone_set('America/New_York');

$root = dirname(__DIR__);
require $root . '/cms/_app/lib/Ratings.php';

// ---------------------------------------------------------------- mini-harness
$passed = 0;
$failed = [];
$skipped = 0;
function check(bool $cond, string $msg): void
{
    if (!$cond) throw new RuntimeException($msg);
}
function same(mixed $expected, mixed $actual, string $msg = ''): void
{
    if ($expected !== $actual) {
        throw new RuntimeException(($msg !== '' ? $msg . ': ' : '') . 'oczekiwano ' . var_export($expected, true)
            . ', jest ' . var_export($actual, true));
    }
}
function test(string $name, callable $fn): void
{
    global $passed, $failed;
    try {
        $fn();
        $passed++;
        echo "  ok    $name\n";
    } catch (Throwable $e) {
        $failed[] = $name;
        echo "  FAIL  $name\n        " . $e->getMessage() . "\n";
    }
}
/** Chwila z czasu UTC ("Y-m-d H:i:s"), niezalezna od strefy domyslnej. */
function utc(string $s): DateTimeImmutable
{
    return new DateTimeImmutable($s, new DateTimeZone('UTC'));
}
/** Chwila z czasu lokalnego Warszawy + przesuniecie w sekundach. */
function waw(string $local, int $plusSec = 0): DateTimeImmutable
{
    $d = Ratings::parseLocal($local);
    return (new DateTimeImmutable('@' . ($d->getTimestamp() + $plusSec)))->setTimezone(Ratings::tz());
}
function state(string $start, string $end, DateTimeImmutable $now, int $open = 10, int $close = 30): string
{
    return Ratings::window($start, $end, $open, $close, $now)['state'];
}

echo "Czesc czysta\n";

// ---------------------------------------------------------------- walidacja
test('score: tylko int 1..10', function () {
    foreach ([1, 5, 10] as $ok) same($ok, Ratings::validScore($ok));
    foreach ([0, 11, -1, '7', 7.0, 7.5, null, true, [], '10'] as $bad) {
        same(null, Ratings::validScore($bad), 'score ' . var_export($bad, true));
    }
});

test('install_id: tylko UUID v4', function () {
    check(Ratings::validInstallId('3f1c2a4e-9b7d-4c1e-8a2b-5d6e7f8a9b0c'), 'v4 male litery');
    check(Ratings::validInstallId('3F1C2A4E-9B7D-4C1E-AA2B-5D6E7F8A9B0C'), 'v4 wielkie litery (iOS)');
    check(!Ratings::validInstallId('3f1c2a4e-9b7d-1c1e-8a2b-5d6e7f8a9b0c'), 'v1 odrzucone');
    check(!Ratings::validInstallId('3f1c2a4e-9b7d-4c1e-7a2b-5d6e7f8a9b0c'), 'zly wariant odrzucony');
    check(!Ratings::validInstallId('3f1c2a4e9b7d4c1e8a2b5d6e7f8a9b0c'), 'bez myslnikow odrzucone');
    check(!Ratings::validInstallId(''), 'pusty');
    check(!Ratings::validInstallId(null), 'null');
    check(!Ratings::validInstallId(12345), 'liczba');
});

test('voter_hash = sha256(install_id + salt), bez surowego UUID', function () {
    $id = '3F1C2A4E-9B7D-4C1E-8A2B-5D6E7F8A9B0C';
    $h = Ratings::voterHash($id, 'sol-testowa-1234567890');
    same(hash('sha256', strtolower($id) . 'sol-testowa-1234567890'), $h);
    same($h, Ratings::voterHash(strtolower($id), 'sol-testowa-1234567890'), 'wielkosc liter bez znaczenia');
    check(!str_contains($h, strtolower(str_replace('-', '', $id))), 'hash nie zawiera UUID');
    check($h !== Ratings::voterHash($id, 'inna-sol-0987654321'), 'sol zmienia hash');
});

// ---------------------------------------------------------------- okno czasu
test('okno: granice start+9:59 / start+10:00 / end+30:00 / end+30:01', function () {
    $s = '2026-10-20 10:00:00';
    $e = '2026-10-20 10:45:00';
    same('not_open', state($s, $e, waw($s, 9 * 60 + 59)), 'start+9:59');
    same('open', state($s, $e, waw($s, 10 * 60)), 'start+10:00');
    same('open', state($s, $e, waw($e, 30 * 60)), 'end+30:00');
    same('closed', state($s, $e, waw($e, 30 * 60 + 1)), 'end+30:01');
    same('not_open', state($s, $e, waw($s, -3600)), 'przed startem');
    same('open', state($s, $e, waw($s, 20 * 60)), 'w trakcie');
});

test('okno: ulamek sekundy po end+30:00 nadal otwarte', function () {
    $now = DateTimeImmutable::createFromFormat('U.u', waw('2026-10-20 11:15:00')->getTimestamp() . '.900000');
    same('open', state('2026-10-20 10:00:00', '2026-10-20 10:45:00', $now));
});

test('okno: opens_at/closes_at w strefie Warszawy (ISO 8601)', function () {
    $w = Ratings::window('2026-10-20 10:00:00', '2026-10-20 10:45:00', 10, 30, utc('2026-10-20 07:00:00'));
    same('2026-10-20T10:10:00+02:00', $w['opens_at']->format(DATE_ATOM));
    same('2026-10-20T11:15:00+02:00', $w['closes_at']->format(DATE_ATOM));
});

test('okno: konfiguracja minut per event (0/0 i 5/60)', function () {
    $s = '2026-10-20 10:00:00';
    $e = '2026-10-20 10:45:00';
    same('open', state($s, $e, waw($s), 0, 0), 'od razu przy starcie');
    same('closed', state($s, $e, waw($e, 1), 0, 0), 'zaraz po koncu');
    same('not_open', state($s, $e, waw($s, 4 * 60 + 59), 5, 60));
    same('open', state($s, $e, waw($e, 60 * 60), 5, 60));
    same('closed', state($s, $e, waw($e, 60 * 60 + 1), 5, 60));
});

test('okno: brak starts_at albo ends_at = nieoceniana', function () {
    same('unrated', state('2026-10-20 10:00:00', '', waw('2026-10-20 10:20:00')));
    same('unrated', Ratings::window(null, '2026-10-20 10:45:00', 10, 30, utc('2026-10-20 08:20:00'))['state']);
    same('unrated', Ratings::window('2026-10-20 10:00:00', null, 10, 30, utc('2026-10-20 08:20:00'))['state']);
    same('unrated', state('smieci', '2026-10-20 10:45:00', utc('2026-10-20 08:20:00')));
});

test('strefa: Europe/Warsaw niezaleznie od strefy PHP (lato +02:00, zima +01:00)', function () {
    $s = '2026-07-01 10:00:00';
    $e = '2026-07-01 11:00:00';
    // 10:10 czasu letniego = 08:10 UTC
    same('not_open', state($s, $e, utc('2026-07-01 08:09:59')));
    same('open', state($s, $e, utc('2026-07-01 08:10:00')));
    // zima: 10:10 = 09:10 UTC
    same('not_open', state('2026-12-01 10:00:00', '2026-12-01 11:00:00', utc('2026-12-01 09:09:59')));
    same('open', state('2026-12-01 10:00:00', '2026-12-01 11:00:00', utc('2026-12-01 09:10:00')));
    foreach (['UTC', 'Asia/Tokyo', 'America/Los_Angeles', 'Europe/Warsaw'] as $tz) {
        date_default_timezone_set($tz);
        same('open', state($s, $e, utc('2026-07-01 08:10:00')), "strefa PHP $tz");
        same('2026-07-01T10:10:00+02:00', Ratings::window($s, $e, 10, 30, utc('2026-07-01 08:10:00'))['opens_at']->format(DATE_ATOM));
    }
    date_default_timezone_set('America/New_York');
});

test('zmiana czasu wiosna (29.03.2026): prelekcja przez 02:00, minuty w czasie rzeczywistym', function () {
    // 01:30 CET (00:30Z) do 03:30 CEST (01:30Z): realnie 1 h
    $s = '2026-03-29 01:30:00';
    $e = '2026-03-29 03:30:00';
    same('not_open', state($s, $e, utc('2026-03-29 00:39:59')), 'otwarcie 01:40 CET = 00:40Z');
    same('open', state($s, $e, utc('2026-03-29 00:40:00')));
    same('open', state($s, $e, utc('2026-03-29 02:00:00')), 'zamkniecie 04:00 CEST = 02:00Z');
    same('closed', state($s, $e, utc('2026-03-29 02:00:01')));
    // start 01:55 CET + 10 min = 01:05Z = 03:05 CEST (nie nieistniejaca 02:05)
    $w = Ratings::window('2026-03-29 01:55:00', '2026-03-29 03:30:00', 10, 30, utc('2026-03-29 01:05:00'));
    same('open', $w['state']);
    same('2026-03-29T03:05:00+02:00', $w['opens_at']->format(DATE_ATOM));
    same('not_open', state('2026-03-29 01:55:00', '2026-03-29 03:30:00', utc('2026-03-29 01:04:59')));
});

test('zmiana czasu jesien (25.10.2026): prelekcja przez 03:00', function () {
    // 01:30 CEST (23:30Z 24.10) do 03:30 CET (02:30Z): realnie 3 h
    $s = '2026-10-25 01:30:00';
    $e = '2026-10-25 03:30:00';
    same('not_open', state($s, $e, utc('2026-10-24 23:39:59')));
    same('open', state($s, $e, utc('2026-10-24 23:40:00')), 'otwarcie 01:40 CEST = 23:40Z');
    same('open', state($s, $e, utc('2026-10-25 03:00:00')), 'zamkniecie 04:00 CET = 03:00Z');
    same('closed', state($s, $e, utc('2026-10-25 03:00:01')));
});

test('zmiana czasu: godzina nieistniejaca i podwojna rozstrzygane jawnie', function () {
    // 02:30 29.03 nie istnieje: przesuniecie do przodu = 03:30 CEST
    same('2026-03-29T03:30:00+02:00', Ratings::parseLocal('2026-03-29 02:30:00')->format(DATE_ATOM));
    // 02:30 25.10 wystepuje dwa razy: pozniejsze wystapienie (czas zimowy)
    same('2026-10-25T02:30:00+01:00', Ratings::parseLocal('2026-10-25 02:30:00')->format(DATE_ATOM));
    same('2026-10-25T01:59:59+02:00', Ratings::parseLocal('2026-10-25 01:59:59')->format(DATE_ATOM));
    same('2026-10-25T03:00:00+01:00', Ratings::parseLocal('2026-10-25 03:00:00')->format(DATE_ATOM));
    same(null, Ratings::parseLocal('2026-02-30 10:00:00'), 'zla data');
    same('2026-10-20T10:00:00+02:00', Ratings::parseLocal('2026-10-20T10:00')->format(DATE_ATOM), 'format bez sekund');
});

// ---------------------------------------------------------------- statystyki
test('stats: srednia, mediana (parzysta i nieparzysta), rozklad, mala proba', function () {
    $s = Ratings::stats([7 => 2, 9 => 1]);           // 7,7,9
    same(3, $s['votes']);
    same(23, $s['sum']);
    same('7.67', number_format($s['avg'], 2));
    same(7.0, $s['median']);
    check($s['small'], '3 glosy = mala proba');
    same([1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0, 7 => 2, 8 => 0, 9 => 1, 10 => 0], $s['dist']);

    $s = Ratings::stats([1 => 1, 4 => 2, 10 => 3]);  // 1,4,4,10,10,10
    same(6, $s['votes']);
    same(7.0, $s['median'], 'mediana parzysta (4+10)/2');
    same('6,5', Ratings::num($s['avg']));
    check(!$s['small'], '6 glosow to nie mala proba');

    $s = Ratings::stats([8 => 4]);
    same(8.0, $s['median']);
    $s = Ratings::stats([3 => 2, 8 => 2]);            // 3,3,8,8
    same(5.5, $s['median']);

    $s = Ratings::stats([]);
    same(0, $s['votes']);
    same(null, $s['avg']);
    same(null, $s['median']);
    $s = Ratings::stats([0 => 5, 11 => 2, 5 => 1]);   // smieci poza skala ignorowane
    same(1, $s['votes']);
});

test('ranking prelegentow: srednia wazona liczba glosow', function () {
    $talkStats = [
        1 => Ratings::stats([10 => 1]),               // 1 glos: 10
        2 => Ratings::stats([6 => 9]),                // 9 glosow: 6
        3 => Ratings::stats([8 => 5]),
        4 => Ratings::stats([]),
    ];
    $ts = [
        ['talk_id' => 1, 'speaker_id' => 100], ['talk_id' => 2, 'speaker_id' => 100],
        ['talk_id' => 3, 'speaker_id' => 200], ['talk_id' => 4, 'speaker_id' => 300],
        ['talk_id' => 99, 'speaker_id' => 100],       // prelekcja spoza eventu: pomijana
    ];
    $sp = [100 => ['name' => 'Anna Kowalska'], 200 => ['name' => 'Jan Nowak'], 300 => ['name' => 'Ewa Brak']];
    $r = Ratings::speakerRanking($talkStats, $ts, $sp);
    same([200, 100, 300], array_column($r, 'speaker_id'), 'kolejnosc');
    same('6.40', number_format($r[1]['avg'], 2), '(10 + 9*6)/10, nie srednia srednich (8,0)');
    same(10, $r[1]['votes']);
    same(2, $r[1]['talks']);
    same(null, $r[2]['avg']);
    check(!$r[0]['small'] && $r[2]['small'], 'mala proba');
});

test('sortowanie prelekcji: srednia (bez glosow na koncu), glosy, agenda', function () {
    $rows = [
        ['order' => 0, 'stats' => Ratings::stats([])],
        ['order' => 1, 'stats' => Ratings::stats([5 => 10])],
        ['order' => 2, 'stats' => Ratings::stats([9 => 2])],
        ['order' => 3, 'stats' => Ratings::stats([5 => 3])],
    ];
    same([2, 1, 3, 0], array_column(Ratings::sortTalks($rows, 'avg', 'desc'), 'order'));
    same([1, 3, 2, 0], array_column(Ratings::sortTalks($rows, 'avg', 'asc'), 'order'));
    same([1, 3, 2, 0], array_column(Ratings::sortTalks($rows, 'votes', 'desc'), 'order'));
    same([0, 1, 2, 3], array_column(Ratings::sortTalks($rows, 'time', 'asc'), 'order'));
});

test('CSV: liczby z przecinkiem, neutralizacja formul, naglowek i 10 kolumn rozkladu', function () {
    same('7,7', Ratings::num(7.666));
    same('', Ratings::num(null));
    same("'=HYPERLINK(\"x\")", Ratings::csvCell('=HYPERLINK("x")'));
    same("'+48 22", Ratings::csvCell('+48 22'));
    same("'-1", Ratings::csvCell('-1'));
    same('Sala A', Ratings::csvCell('Sala A'));
    $rows = Ratings::csvTalks([[
        'title' => '@cmd', 'speakers' => 'Anna Kowalska', 'room' => 'Sala A', 'day' => 'Dzień 1 20.10',
        'time' => '10:00 do 10:45', 'stats' => Ratings::stats([7 => 2, 9 => 1]),
    ]]);
    same(19, count($rows[0]));
    same(['Tytuł', 'Prelegenci', 'Sala', 'Dzień', 'Godzina', 'Liczba głosów', 'Średnia', 'Mediana', 'Mała próba', 'Ocena 1'],
        array_slice($rows[0], 0, 10));
    same(["'@cmd", 'Anna Kowalska', 'Sala A', 'Dzień 1 20.10', '10:00 do 10:45', '3', '7,7', '7,0', 'tak', '0'],
        array_slice($rows[1], 0, 10));
    same('2', $rows[1][15], 'Ocena 7');
    $rows = Ratings::csvTalks([['title' => 'x', 'speakers' => '', 'room' => null, 'day' => '', 'time' => '', 'stats' => Ratings::stats([])]]);
    same(['0', '', '', ''], array_slice($rows[1], 5, 4), 'bez glosow: puste srednia, mediana, mala proba');
});

// ---------------------------------------------------------------- baza danych
$dsn = getenv('ESK_TEST_DB_DSN') ?: '';
echo "\nCzesc z baza danych\n";
if ($dsn === '') {
    $skipped++;
    echo "  SKIP  brak ESK_TEST_DB_DSN (patrz naglowek pliku)\n";
} elseif (!preg_match('/dbname=[^;]*test/i', $dsn)) {
    $failed[] = 'bezpiecznik';
    echo "  FAIL  ESK_TEST_DB_DSN musi wskazywac baze z 'test' w nazwie (test zmienia schemat)\n";
} else {
    $pdo = new PDO($dsn, getenv('ESK_TEST_DB_USER') ?: '', getenv('ESK_TEST_DB_PASS') ?: '', [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
    $runSql = function (string $file) use ($pdo): void {
        $sql = preg_replace('/^\s*--.*$/m', '', (string)file_get_contents($file));
        foreach (preg_split('/;\s*(\r?\n|$)/', $sql) as $stmt) {
            if (trim($stmt) !== '') $pdo->exec($stmt);
        }
    };
    $col = function (string $table, string $column) use ($pdo): ?array {
        $st = $pdo->prepare('SELECT COLUMN_DEFAULT, IS_NULLABLE, DATA_TYPE FROM information_schema.COLUMNS
                             WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?');
        $st->execute([$table, $column]);
        return $st->fetch() ?: null;
    };
    $migration = $root . '/db/migrations/2026_09_ratings.sql';

    test('schema.sql + migracja na bazie SPRZED ocen (2x, idempotentna)', function () use ($pdo, $runSql, $col, $root, $migration) {
        $runSql($root . '/db/schema.sql');
        // cofnij do stanu sprzed migracji (jak produkcja dzis)
        $pdo->exec('DROP TABLE IF EXISTS talk_ratings, rating_rate_hits');
        foreach (['ratings_enabled', 'ratings_open_after_start_min', 'ratings_close_after_end_min'] as $c) {
            if ($col('events', $c)) $pdo->exec("ALTER TABLE events DROP COLUMN $c");
        }
        check($col('events', 'ratings_enabled') === null, 'kolumna usunieta przed migracja');
        $runSql($migration);
        $runSql($migration);   // drugi raz: bez bledu
        same('1', trim((string)$col('events', 'ratings_enabled')['COLUMN_DEFAULT'], "'"));
        same('10', trim((string)$col('events', 'ratings_open_after_start_min')['COLUMN_DEFAULT'], "'"));
        same('30', trim((string)$col('events', 'ratings_close_after_end_min')['COLUMN_DEFAULT'], "'"));
        same('NO', $col('events', 'ratings_enabled')['IS_NULLABLE']);
        check($col('talk_ratings', 'voter_hash') !== null, 'talk_ratings istnieje');
        check($col('rating_rate_hits', 'key_hash') !== null, 'rating_rate_hits istnieje');
        $runSql($root . '/db/schema.sql');   // schema.sql na zmigrowanej bazie tez przechodzi
    });

    // ---- dane testowe (kody RTEST*, sprzatane na starcie i koncu)
    $codes = ['RTEST1', 'RTEST2', 'RTEST3', 'RTEST4'];
    $cleanup = function () use ($pdo, $codes): void {
        $in = implode(',', array_fill(0, count($codes), '?'));
        $pdo->prepare("DELETE FROM events WHERE access_code IN ($in)")->execute($codes);
        $pdo->exec('DELETE FROM rating_rate_hits');
    };
    $cleanup();
    $mkEvent = function (string $code, string $status = 'published', int $enabled = 1) use ($pdo): int {
        $pdo->prepare("INSERT INTO events (slug, name, access_code, status, ratings_enabled) VALUES (?, ?, ?, ?, ?)")
            ->execute([strtolower($code), "Event $code", $code, $status, $enabled]);
        return (int)$pdo->lastInsertId();
    };
    $mkTalk = function (int $eventId, string $title, ?string $s, ?string $e) use ($pdo): int {
        $pdo->prepare('INSERT INTO talks (event_id, title, starts_at, ends_at) VALUES (?, ?, ?, ?)')
            ->execute([$eventId, $title, $s, $e]);
        return (int)$pdo->lastInsertId();
    };
    $ev1 = $mkEvent('RTEST1');
    $ev2 = $mkEvent('RTEST2');
    $ev3 = $mkEvent('RTEST3', 'published', 0);   // oceny wylaczone
    $ev4 = $mkEvent('RTEST4', 'draft');
    $t1 = $mkTalk($ev1, 'Nowe wytyczne', '2026-10-20 10:00:00', '2026-10-20 10:45:00');
    $t1b = $mkTalk($ev1, 'Bez godzin', null, null);
    $t1c = $mkTalk($ev1, 'Druga prelekcja', '2026-10-20 11:00:00', '2026-10-20 11:30:00');
    $t2 = $mkTalk($ev2, 'Z innego eventu', '2026-10-20 10:00:00', '2026-10-20 10:45:00');
    $t3 = $mkTalk($ev3, 'Oceny wylaczone', '2026-10-20 10:00:00', '2026-10-20 10:45:00');
    $t4 = $mkTalk($ev4, 'Szkic', '2026-10-20 10:00:00', '2026-10-20 10:45:00');
    $sp1 = (function () use ($pdo, $ev1, $t1, $t1c): int {
        $pdo->prepare("INSERT INTO speakers (event_id, first_name, last_name) VALUES (?, 'Anna', 'Kowalska')")->execute([$ev1]);
        $id = (int)$pdo->lastInsertId();
        $pdo->prepare('INSERT INTO talk_speakers (talk_id, speaker_id) VALUES (?, ?), (?, ?)')->execute([$t1, $id, $t1c, $id]);
        return $id;
    })();

    $salt = 'sol-testowa-0123456789abcdef';
    $uuidA = '3f1c2a4e-9b7d-4c1e-8a2b-5d6e7f8a9b0c';
    $uuidB = '7a6b5c4d-3e2f-4a1b-9c8d-7e6f5a4b3c2d';
    $inWindow = waw('2026-10-20 10:20:00');
    $submit = fn(string $code, int $talk, ?array $body, DateTimeImmutable $now, string $ip = '203.0.113.7')
        => Ratings::submit($pdo, $code, $talk, $body, $ip, $salt, $now);
    $row = function (int $talk, string $uuid) use ($pdo, $salt): ?array {
        $st = $pdo->prepare('SELECT * FROM talk_ratings WHERE talk_id = ? AND voter_hash = ?');
        $st->execute([$talk, Ratings::voterHash($uuid, $salt)]);
        return $st->fetch() ?: null;
    };

    test('POST: poprawny glos w oknie = 200 {ok, score}, w bazie tylko hash', function () use ($submit, $row, $pdo, $t1, $uuidA, $inWindow, $salt) {
        [$st, $body] = $submit('rtest1', $t1, ['install_id' => $uuidA, 'score' => 7], $inWindow);
        same(200, $st);
        same(['ok' => true, 'score' => 7], $body);
        $r = $row($t1, $uuidA);
        same(7, (int)$r['score']);
        same(hash('sha256', $uuidA . $salt), $r['voter_hash']);
        same('2026-10-20 10:20:00', $r['created_at'], 'czas lokalny Warszawy');
        same(64, strlen((string)$r['ip_hash']));
        $dump = json_encode($pdo->query('SELECT * FROM talk_ratings')->fetchAll());
        check(!str_contains($dump, $uuidA) && !str_contains($dump, '203.0.113.7'), 'brak surowego UUID i IP w bazie');
    });

    test('POST: upsert, drugi glos tego urzadzenia nadpisuje ocene (1 wiersz)', function () use ($submit, $row, $pdo, $t1, $uuidA) {
        [$st, $body] = $submit('RTEST1', $t1, ['install_id' => strtoupper($uuidA), 'score' => 3], waw('2026-10-20 10:50:00'));
        same(200, $st);
        same(3, $body['score']);
        $r = $row($t1, $uuidA);
        same(3, (int)$r['score']);
        same('2026-10-20 10:20:00', $r['created_at'], 'created_at bez zmian');
        same('2026-10-20 10:50:00', $r['updated_at'], 'updated_at nowy');
        $st = $pdo->prepare('SELECT COUNT(*) FROM talk_ratings WHERE talk_id = ?');
        $st->execute([$t1]);
        same(1, (int)$st->fetchColumn());
    });

    test('POST: okno 409 window_not_open (start+9:59) i window_closed (end+30:01)', function () use ($submit, $t1, $uuidB) {
        [$st, $body] = $submit('RTEST1', $t1, ['install_id' => $uuidB, 'score' => 5], waw('2026-10-20 10:09:59'));
        same(409, $st);
        same(['error' => 'window_not_open', 'opens_at' => '2026-10-20T10:10:00+02:00'], $body);
        [$st, ] = $submit('RTEST1', $t1, ['install_id' => $uuidB, 'score' => 5], waw('2026-10-20 10:10:00'));
        same(200, $st, 'start+10:00');
        [$st, ] = $submit('RTEST1', $t1, ['install_id' => $uuidB, 'score' => 6], waw('2026-10-20 11:15:00'));
        same(200, $st, 'end+30:00');
        [$st, $body] = $submit('RTEST1', $t1, ['install_id' => $uuidB, 'score' => 9], waw('2026-10-20 11:15:01'));
        same(409, $st);
        same(['error' => 'window_closed', 'closed_at' => '2026-10-20T11:15:00+02:00'], $body);
    });

    test('POST: event z wylaczonymi ocenami = 403 ratings_disabled', function () use ($submit, $t3, $uuidA, $inWindow) {
        same([403, ['error' => 'ratings_disabled']], $submit('RTEST3', $t3, ['install_id' => $uuidA, 'score' => 7], $inWindow));
    });

    test('POST: talk z innego eventu = 404 talk_not_found', function () use ($submit, $t2, $uuidA, $inWindow) {
        same([404, ['error' => 'talk_not_found']], $submit('RTEST1', $t2, ['install_id' => $uuidA, 'score' => 7], $inWindow));
        same([404, ['error' => 'talk_not_found']], $submit('RTEST1', 999999999, ['install_id' => $uuidA, 'score' => 7], $inWindow));
    });

    test('POST: event nieopublikowany albo nieistniejacy = 404', function () use ($submit, $t4, $uuidA, $inWindow) {
        same([404, ['error' => 'not_found']], $submit('RTEST4', $t4, ['install_id' => $uuidA, 'score' => 7], $inWindow));
        same([404, ['error' => 'not_found']], $submit('NIEMA99', $t4, ['install_id' => $uuidA, 'score' => 7], $inWindow));
    });

    test('POST: walidacja 400/422 i prelekcja bez godzin 409 not_rateable', function () use ($submit, $t1, $t1b, $uuidA, $inWindow) {
        same([400, ['error' => 'invalid_json']], $submit('RTEST1', $t1, null, $inWindow));
        same([422, ['error' => 'invalid_install_id']], $submit('RTEST1', $t1, ['install_id' => 'x', 'score' => 7], $inWindow));
        same([422, ['error' => 'invalid_install_id']], $submit('RTEST1', $t1, ['score' => 7], $inWindow));
        foreach ([0, 11, '7', 7.0, null] as $bad) {
            same([422, ['error' => 'invalid_score']], $submit('RTEST1', $t1, ['install_id' => $uuidA, 'score' => $bad], $inWindow));
        }
        same([409, ['error' => 'not_rateable']], $submit('RTEST1', $t1b, ['install_id' => $uuidA, 'score' => 7], $inWindow));
    });

    test('rate-limit: per voter i per IP (429), okno przesuwne', function () use ($pdo, $submit, $t1c, $inWindow) {
        $pdo->exec('DELETE FROM rating_rate_hits');
        $uuid = '11111111-2222-4333-8444-555555555555';
        putenv('RATING_RL_VOTER_MAX=3');
        try {
            for ($i = 1; $i <= 3; $i++) {
                same(200, $submit('RTEST1', $t1c, ['install_id' => $uuid, 'score' => $i], waw('2026-10-20 11:12:00'))[0], "glos $i");
            }
            same([429, ['error' => 'rate_limited']], $submit('RTEST1', $t1c, ['install_id' => $uuid, 'score' => 4], waw('2026-10-20 11:12:00')));
            same(200, $submit('RTEST1', $t1c, ['install_id' => $uuid, 'score' => 5], waw('2026-10-20 11:22:01'))[0], 'po 10 min znowu wolno');
        } finally {
            putenv('RATING_RL_VOTER_MAX');
        }
        putenv('RATING_RL_IP_MAX=2');
        try {
            $ip = '198.51.100.9';
            same(200, $submit('RTEST1', $t1c, ['install_id' => '21111111-2222-4333-8444-555555555555', 'score' => 7], $inWindow->modify('+50 minutes'), $ip)[0]);
            same(200, $submit('RTEST1', $t1c, ['install_id' => '31111111-2222-4333-8444-555555555555', 'score' => 7], $inWindow->modify('+50 minutes'), $ip)[0]);
            same(429, $submit('RTEST1', $t1c, ['install_id' => '41111111-2222-4333-8444-555555555555', 'score' => 7], $inWindow->modify('+50 minutes'), $ip)[0]);
            same(200, $submit('RTEST1', $t1c, ['install_id' => '41111111-2222-4333-8444-555555555555', 'score' => 7], $inWindow->modify('+50 minutes'), '198.51.100.10')[0], 'inne IP');
        } finally {
            putenv('RATING_RL_IP_MAX');
        }
    });

    test('GET mine: oceny tylko tego urzadzenia [{talk_id, score}]', function () use ($pdo, $salt, $t1, $uuidA, $uuidB) {
        [$st, $body] = Ratings::mine($pdo, 'RTEST1', $uuidA, '203.0.113.7', $salt, waw('2026-10-20 12:00:00'));
        same(200, $st);
        same([['talk_id' => $t1, 'score' => 3]], $body);
        [, $body] = Ratings::mine($pdo, 'rtest1', strtoupper($uuidB), '203.0.113.7', $salt, waw('2026-10-20 12:00:00'));
        same([['talk_id' => $t1, 'score' => 6]], $body);
        [, $body] = Ratings::mine($pdo, 'RTEST1', '99999999-2222-4333-8444-555555555555', '203.0.113.7', $salt, waw('2026-10-20 12:00:00'));
        same([], $body);
        same([422, ['error' => 'invalid_install_id']], Ratings::mine($pdo, 'RTEST1', 'zly', '203.0.113.7', $salt, waw('2026-10-20 12:00:00')));
        same([404, ['error' => 'not_found']], Ratings::mine($pdo, 'RTEST4', $uuidA, '203.0.113.7', $salt, waw('2026-10-20 12:00:00')));
    });

    test('raport CMS: statystyki prelekcji, ranking, liczba urzadzen', function () use ($pdo, $ev1, $t1, $t1b, $t1c, $sp1) {
        $rep = Ratings::report($pdo, $ev1);
        $byId = array_column($rep['talks'], null, 'id');
        same(2, $byId[$t1]['stats']['votes']);                  // uuidA=3, uuidB=6
        same('4,5', Ratings::num($byId[$t1]['stats']['avg']));
        same('Anna Kowalska', $byId[$t1]['speakers']);
        same('10:00 do 10:45', $byId[$t1]['time']);
        same(4, $byId[$t1c]['stats']['votes'], 'glosy z testu rate-limitu (4 urzadzenia)');
        same(0, $byId[$t1b]['stats']['votes']);
        same(6, $rep['total_votes']);
        same(6, $rep['voters']);
        same(2, $rep['rated_talks']);
        same($sp1, $rep['speakers'][0]['speaker_id']);
        same(6, $rep['speakers'][0]['votes']);
        same(count($rep['talks']) + 1, count(Ratings::csvTalks($rep['talks'])), 'CSV: naglowek + wiersz na prelekcje');
    });

    test('usuniecie eventu kasuje jego oceny (FK ON DELETE CASCADE)', function () use ($pdo, $ev1) {
        $pdo->prepare('DELETE FROM events WHERE id = ?')->execute([$ev1]);
        $st = $pdo->prepare('SELECT COUNT(*) FROM talk_ratings WHERE event_id = ?');
        $st->execute([$ev1]);
        same(0, (int)$st->fetchColumn());
    });

    $cleanup();
}

echo "\nWynik: {$passed} ok, " . count($failed) . " bledow" . ($skipped ? ", {$skipped} pominiete" : '') . "\n";
exit($failed ? 1 : 0);
