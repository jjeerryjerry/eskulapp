<?php
declare(strict_types=1);

/**
 * Oceny prelekcji 1-10, anonimowe (docs/SPEC-OCENY.md).
 *
 * Czesc czysta (bez DB, testowana w web/tests/ratings_test.php): parseLocal(),
 * window(), validScore(), validInstallId(), voterHash(), stats(),
 * speakerRanking(), sortTalks(), csv*().
 * Czesc z DB: submit(), mine(), hit() (rate-limit), report().
 *
 * Czas: talks.starts_at/ends_at to DATETIME bez strefy w czasie lokalnym
 * Europe/Warsaw. Okno liczymy jawnie w tej strefie (nie ufamy strefie hostingu
 * ani MySQL). "Teraz" to wylacznie zegar serwera w chwili przyjecia glosu,
 * zegar telefonu i ewentualny client_ts sa ignorowane.
 */
final class Ratings
{
    public const TZ = 'Europe/Warsaw';
    public const SCORE_MIN = 1;
    public const SCORE_MAX = 10;
    public const SMALL_SAMPLE = 5;            // < 5 glosow = "mala proba" w CMS
    public const DEFAULT_OPEN_MIN = 10;       // okno otwiera sie starts_at + 10 min
    public const DEFAULT_CLOSE_MIN = 30;      // i zamyka ends_at + 30 min
    public const MAX_WINDOW_MIN = 1440;       // limit minut w formularzu CMS

    // Rate-limit (okno przesuwne 10 min). Limit per IP celowo wyzszy niz przyklad
    // ze specyfikacji (60): cala sala na Wi-Fi obiektu wychodzi zwykle z JEDNEGO
    // publicznego IP (NAT), a glosy splywaja w tych samych 30 min po prelekcji.
    // Nadpisywalne w _app/.env: RATING_RL_IP_MAX, RATING_RL_VOTER_MAX.
    public const RL_WINDOW_SEC = 600;
    public const RL_IP_MAX_DEFAULT = 600;
    public const RL_VOTER_MAX_DEFAULT = 30;

    public static function tz(): DateTimeZone
    {
        static $tz = null;
        return $tz ??= new DateTimeZone(self::TZ);
    }

    public static function now(): DateTimeImmutable
    {
        return new DateTimeImmutable('now', self::tz());
    }

    // ------------------------------------------------------------ czas / okno

    /**
     * "Y-m-d H:i[:s]" w czasie lokalnym Warszawy -> chwila w czasie (strefa Warszawy).
     * Zmiana czasu rozstrzygana jawnie, niezaleznie od wersji PHP i strefy serwera:
     *  - godzina podwojna (pazdziernik, 02:00-02:59 dwa razy) = pozniejsze wystapienie
     *    (czas zimowy),
     *  - godzina nieistniejaca (marzec, 02:00-02:59) = przesuniecie do przodu o dlugosc
     *    luki (02:30 -> 03:30 czasu letniego).
     * Tak samo licza apki (Android: withLaterOffsetAtOverlap, iOS: ratingLocalDate).
     */
    public static function parseLocal(?string $s): ?DateTimeImmutable
    {
        if ($s === null) return null;
        if (!preg_match('/^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})(?::(\d{2}))?$/', trim($s), $m)) return null;
        [$y, $mo, $d, $h, $i] = [(int)$m[1], (int)$m[2], (int)$m[3], (int)$m[4], (int)$m[5]];
        $sec = (int)($m[6] ?? 0);
        if (!checkdate($mo, $d, $y) || $h > 23 || $i > 59 || $sec > 59) return null;

        $wall = gmmktime($h, $i, $sec, $mo, $d, $y);   // zegar scienny liczony "jak UTC"
        $tz = self::tz();
        $offset = static fn(int $ts): int => $tz->getOffset(new DateTimeImmutable('@' . $ts));
        $before = $offset($wall - 43200);                // offset sprzed ewentualnej zmiany
        $after = $offset($wall + 43200);                 // i po niej (max 1 zmiana na dobe)
        $valid = [];
        foreach (array_unique([$before, $after]) as $o) {
            $t = $wall - $o;
            if ($offset($t) === $o) $valid[] = $t;
        }
        $ts = $valid ? max($valid) : $wall - $before;
        return (new DateTimeImmutable('@' . $ts))->setTimezone($tz);
    }

    /**
     * Okno oceniania prelekcji. Czysta funkcja: bez DB, "teraz" wstrzykiwane.
     * Granice wlacznie, z dokladnoscia do sekundy: start+10:00 przyjmuje,
     * start+9:59 odrzuca, end+30:00 przyjmuje, end+30:01 odrzuca.
     *
     * @return array{state:string, opens_at:?DateTimeImmutable, closes_at:?DateTimeImmutable}
     *   state: 'unrated' (brak starts_at lub ends_at) | 'not_open' | 'open' | 'closed'
     */
    public static function window(?string $startsAt, ?string $endsAt, int $openAfterStartMin,
                                  int $closeAfterEndMin, DateTimeImmutable $now): array
    {
        $start = self::parseLocal($startsAt);
        $end = self::parseLocal($endsAt);
        if ($start === null || $end === null) {
            return ['state' => 'unrated', 'opens_at' => null, 'closes_at' => null];
        }
        $opens = self::plusMinutes($start, $openAfterStartMin);
        $closes = self::plusMinutes($end, $closeAfterEndMin);
        $t = $now->getTimestamp();   // pelne sekundy (ulamki sekundy nie zamykaja okna)
        $state = $t < $opens->getTimestamp() ? 'not_open'
               : ($t > $closes->getTimestamp() ? 'closed' : 'open');
        return ['state' => $state, 'opens_at' => $opens, 'closes_at' => $closes];
    }

    /** Dodaje minuty w czasie rzeczywistym (nie sciennym): zmiana czasu nie przesuwa okna. */
    private static function plusMinutes(DateTimeImmutable $d, int $min): DateTimeImmutable
    {
        return (new DateTimeImmutable('@' . ($d->getTimestamp() + $min * 60)))->setTimezone(self::tz());
    }

    // ------------------------------------------------------------ walidacja

    /** Ocena: wylacznie liczba calkowita JSON 1..10 (bez "7" i 7.0). */
    public static function validScore(mixed $v): ?int
    {
        return (is_int($v) && $v >= self::SCORE_MIN && $v <= self::SCORE_MAX) ? $v : null;
    }

    /** install_id: UUID v4 (wielkosc liter dowolna, iOS generuje wielkie). */
    public static function validInstallId(mixed $v): bool
    {
        return is_string($v)
            && preg_match('/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i', $v) === 1;
    }

    /** sha256(install_id + RATING_SALT); install_id normalizowany do malych liter. */
    public static function voterHash(string $installId, string $salt): string
    {
        return hash('sha256', strtolower($installId) . $salt);
    }

    public static function ipHash(string $ip, string $salt): string
    {
        return hash('sha256', 'ip:' . $ip . $salt);
    }

    /** Cialo JSON zadania (maks. 4 KB) jako tablica albo null. */
    public static function readJsonBody(): ?array
    {
        $raw = file_get_contents('php://input', false, null, 0, 4096);
        if (!is_string($raw) || $raw === '') return null;
        try {
            $data = json_decode($raw, true, 4, JSON_THROW_ON_ERROR);
        } catch (JsonException) {
            return null;
        }
        return is_array($data) ? $data : null;
    }

    // ------------------------------------------------------------ API (DB)

    /**
     * POST /api/public/events/{code}/talks/{talkId}/rating  body {"install_id","score"}
     * @return array{0:int,1:array} [status HTTP, cialo JSON]
     */
    public static function submit(PDO $pdo, string $code, int $talkId, ?array $body, string $ip,
                                  string $salt, DateTimeImmutable $now): array
    {
        $ipHash = self::ipHash($ip, $salt);
        if (!self::hit($pdo, 'ip', $ipHash, self::ipLimit(), $now)) return [429, ['error' => 'rate_limited']];
        if ($body === null) return [400, ['error' => 'invalid_json']];

        $installId = $body['install_id'] ?? null;
        if (!self::validInstallId($installId)) return [422, ['error' => 'invalid_install_id']];
        $score = self::validScore($body['score'] ?? null);
        if ($score === null) return [422, ['error' => 'invalid_score']];

        $voter = self::voterHash($installId, $salt);
        if (!self::hit($pdo, 'voter', $voter, self::voterLimit(), $now)) return [429, ['error' => 'rate_limited']];

        $st = $pdo->prepare("SELECT id, ratings_enabled, ratings_open_after_start_min, ratings_close_after_end_min
                             FROM events WHERE access_code = ? AND status = 'published' LIMIT 1");
        $st->execute([strtoupper($code)]);
        $ev = $st->fetch();
        if (!$ev) return [404, ['error' => 'not_found']];
        if (!(int)$ev['ratings_enabled']) return [403, ['error' => 'ratings_disabled']];

        $st = $pdo->prepare('SELECT id, starts_at, ends_at FROM talks WHERE id = ? AND event_id = ? LIMIT 1');
        $st->execute([$talkId, (int)$ev['id']]);
        $talk = $st->fetch();
        if (!$talk) return [404, ['error' => 'talk_not_found']];

        $w = self::window($talk['starts_at'], $talk['ends_at'],
            (int)$ev['ratings_open_after_start_min'], (int)$ev['ratings_close_after_end_min'], $now);
        if ($w['state'] === 'unrated') return [409, ['error' => 'not_rateable']];
        if ($w['state'] === 'not_open') {
            return [409, ['error' => 'window_not_open', 'opens_at' => $w['opens_at']->format(DATE_ATOM)]];
        }
        if ($w['state'] === 'closed') {
            return [409, ['error' => 'window_closed', 'closed_at' => $w['closes_at']->format(DATE_ATOM)]];
        }

        // Czas lokalny Warszawy, jak pozostale DATETIME (nie NOW() MySQL, patrz §2 spec).
        $ts = $now->setTimezone(self::tz())->format('Y-m-d H:i:s');
        $pdo->prepare('INSERT INTO talk_ratings (event_id, talk_id, voter_hash, score, created_at, updated_at, ip_hash)
                       VALUES (?, ?, ?, ?, ?, ?, ?)
                       ON DUPLICATE KEY UPDATE score = VALUES(score), updated_at = VALUES(updated_at),
                                               ip_hash = VALUES(ip_hash)')
            ->execute([(int)$ev['id'], $talkId, $voter, $score, $ts, $ts, $ipHash]);
        return [200, ['ok' => true, 'score' => $score]];
    }

    /**
     * GET /api/public/events/{code}/ratings/mine?install_id=...
     * Oceny tego urzadzenia: [{talk_id, score}] (odtworzenie stanu apki).
     * @return array{0:int,1:array}
     */
    public static function mine(PDO $pdo, string $code, mixed $installId, string $ip, string $salt,
                                DateTimeImmutable $now): array
    {
        if (!self::hit($pdo, 'ip', self::ipHash($ip, $salt), self::ipLimit(), $now)) {
            return [429, ['error' => 'rate_limited']];
        }
        if (!self::validInstallId($installId)) return [422, ['error' => 'invalid_install_id']];
        $voter = self::voterHash($installId, $salt);
        if (!self::hit($pdo, 'voter', $voter, self::voterLimit(), $now)) return [429, ['error' => 'rate_limited']];

        $st = $pdo->prepare("SELECT id FROM events WHERE access_code = ? AND status IN ('published','archived') LIMIT 1");
        $st->execute([strtoupper($code)]);
        $eventId = $st->fetchColumn();
        if ($eventId === false) return [404, ['error' => 'not_found']];

        $st = $pdo->prepare('SELECT talk_id, score FROM talk_ratings WHERE event_id = ? AND voter_hash = ? ORDER BY talk_id');
        $st->execute([(int)$eventId, $voter]);
        $out = [];
        foreach ($st->fetchAll() as $r) $out[] = ['talk_id' => (int)$r['talk_id'], 'score' => (int)$r['score']];
        return [200, $out];
    }

    /**
     * Rate-limit w oknie przesuwnym (tabela rating_rate_hits, czas UTC).
     * true = wolno (trafienie zapisane), false = limit przekroczony (nie zapisujemy,
     * wiec blokada mija sama po oknie).
     */
    public static function hit(PDO $pdo, string $scope, string $keyHash, int $max, DateTimeImmutable $now,
                               int $windowSec = self::RL_WINDOW_SEC): bool
    {
        $utc = $now->setTimezone(new DateTimeZone('UTC'));
        $since = $utc->modify('-' . $windowSec . ' seconds')->format('Y-m-d H:i:s');
        $st = $pdo->prepare('SELECT COUNT(*) FROM rating_rate_hits WHERE scope = ? AND key_hash = ? AND created_at > ?');
        $st->execute([$scope, $keyHash, $since]);
        if ((int)$st->fetchColumn() >= $max) return false;
        $pdo->prepare('INSERT INTO rating_rate_hits (scope, key_hash, created_at) VALUES (?, ?, ?)')
            ->execute([$scope, $keyHash, $utc->format('Y-m-d H:i:s')]);
        if (random_int(1, 200) === 1) {   // okazjonalne sprzatanie starych trafien
            $pdo->prepare('DELETE FROM rating_rate_hits WHERE created_at < ?')
                ->execute([$utc->modify('-1 day')->format('Y-m-d H:i:s')]);
        }
        return true;
    }

    public static function ipLimit(): int
    {
        return self::envInt('RATING_RL_IP_MAX', self::RL_IP_MAX_DEFAULT);
    }

    public static function voterLimit(): int
    {
        return self::envInt('RATING_RL_VOTER_MAX', self::RL_VOTER_MAX_DEFAULT);
    }

    private static function envInt(string $key, int $default): int
    {
        $v = function_exists('env') ? env($key) : (getenv($key) ?: null);
        return ($v !== null && ctype_digit($v) && (int)$v > 0) ? (int)$v : $default;
    }

    // ------------------------------------------------------------ CMS: wyniki

    /**
     * Statystyki z rozkladu ocen.
     * @param array<int,int> $dist ocena => liczba glosow
     * @return array{votes:int, sum:int, avg:?float, median:?float, dist:array<int,int>, small:bool}
     */
    public static function stats(array $dist): array
    {
        $full = array_fill(self::SCORE_MIN, self::SCORE_MAX, 0);
        foreach ($dist as $score => $count) {
            $score = (int)$score;
            if ($score >= self::SCORE_MIN && $score <= self::SCORE_MAX) $full[$score] += (int)$count;
        }
        $n = array_sum($full);
        $sum = 0;
        foreach ($full as $score => $count) $sum += $score * $count;
        if ($n === 0) {
            return ['votes' => 0, 'sum' => 0, 'avg' => null, 'median' => null, 'dist' => $full, 'small' => true];
        }
        // k-ta (od 1) wartosc posortowanej listy glosow, liczona z histogramu
        $kth = static function (int $k) use ($full): int {
            $acc = 0;
            foreach ($full as $score => $count) {
                $acc += $count;
                if ($acc >= $k) return $score;
            }
            return self::SCORE_MAX;
        };
        $median = $n % 2 === 1
            ? (float)$kth(intdiv($n + 1, 2))
            : ($kth(intdiv($n, 2)) + $kth(intdiv($n, 2) + 1)) / 2;
        return [
            'votes' => $n, 'sum' => $sum, 'avg' => $sum / $n, 'median' => (float)$median,
            'dist' => $full, 'small' => $n < self::SMALL_SAMPLE,
        ];
    }

    /**
     * Ranking prelegentow: srednia wazona liczba glosow, czyli suma wszystkich ocen
     * z ich prelekcji podzielona przez liczbe tych glosow.
     * @param array<int,array> $talkStats   talk_id => stats()
     * @param array $talkSpeakers           lista ['talk_id'=>, 'speaker_id'=>]
     * @param array<int,array> $speakers    speaker_id => ['name'=>, 'title'=>]
     */
    public static function speakerRanking(array $talkStats, array $talkSpeakers, array $speakers): array
    {
        $acc = [];
        foreach ($talkSpeakers as $ts) {
            $sid = (int)$ts['speaker_id'];
            $tid = (int)$ts['talk_id'];
            if (!isset($speakers[$sid], $talkStats[$tid])) continue;
            $acc[$sid] ??= [
                'speaker_id' => $sid, 'name' => $speakers[$sid]['name'],
                'title' => $speakers[$sid]['title'] ?? null, 'talks' => 0, 'votes' => 0, 'sum' => 0,
            ];
            $acc[$sid]['talks']++;
            $acc[$sid]['votes'] += $talkStats[$tid]['votes'];
            $acc[$sid]['sum'] += $talkStats[$tid]['sum'];
        }
        $rows = [];
        foreach ($acc as $a) {
            $a['avg'] = $a['votes'] > 0 ? $a['sum'] / $a['votes'] : null;
            $a['small'] = $a['votes'] < self::SMALL_SAMPLE;
            $rows[] = $a;
        }
        usort($rows, static fn(array $x, array $y): int =>
            [$y['avg'] !== null, $y['avg'] ?? 0.0, $y['votes'], $x['name']]
            <=> [$x['avg'] !== null, $x['avg'] ?? 0.0, $x['votes'], $y['name']]);
        return $rows;
    }

    /**
     * Sortowanie wierszy prelekcji: 'avg' | 'votes' | 'time' (kolejnosc agendy),
     * $dir 'asc' | 'desc'. Prelekcje bez glosow zawsze na koncu przy sortowaniu po sredniej.
     */
    public static function sortTalks(array $rows, string $sort, string $dir): array
    {
        $sign = $dir === 'asc' ? 1 : -1;
        usort($rows, static function (array $a, array $b) use ($sort, $sign): int {
            $byOrder = $a['order'] <=> $b['order'];
            if ($sort === 'time') return $sign * $byOrder;
            if ($sort === 'votes') {
                return ($sign * ($a['stats']['votes'] <=> $b['stats']['votes'])) ?: $byOrder;
            }
            $aa = $a['stats']['avg'];
            $ba = $b['stats']['avg'];
            if ($aa === null || $ba === null) {
                return (($aa === null) <=> ($ba === null)) ?: $byOrder;
            }
            return ($sign * ($aa <=> $ba)) ?: ($b['stats']['votes'] <=> $a['stats']['votes']) ?: $byOrder;
        });
        return $rows;
    }

    /**
     * Pelny raport ocen eventu dla CMS.
     * @return array{talks:array, speakers:array, total_votes:int, voters:int, rated_talks:int}
     */
    public static function report(PDO $pdo, int $eventId): array
    {
        $q = static function (string $sql) use ($pdo, $eventId): array {
            $st = $pdo->prepare($sql);
            $st->execute([$eventId]);
            return $st->fetchAll();
        };
        $talks = $q('SELECT t.id, t.title, t.starts_at, t.ends_at, r.name AS room, d.label AS day_label, d.date AS day_date
                     FROM talks t
                     LEFT JOIN rooms r ON r.id = t.room_id
                     LEFT JOIN event_days d ON d.id = t.day_id
                     WHERE t.event_id = ?
                     ORDER BY t.starts_at IS NULL, t.starts_at, t.sort, t.id');
        $distRows = $q('SELECT talk_id, score, COUNT(*) AS c FROM talk_ratings WHERE event_id = ? GROUP BY talk_id, score');
        $speakerRows = $q('SELECT id, first_name, last_name, title FROM speakers WHERE event_id = ?');
        $talkSpeakers = $q('SELECT ts.talk_id, ts.speaker_id FROM talk_speakers ts
                            JOIN talks t ON t.id = ts.talk_id WHERE t.event_id = ?');
        $voters = $q('SELECT COUNT(DISTINCT voter_hash) AS n FROM talk_ratings WHERE event_id = ?');

        $dist = [];
        foreach ($distRows as $r) $dist[(int)$r['talk_id']][(int)$r['score']] = (int)$r['c'];
        $speakers = [];
        foreach ($speakerRows as $s) {
            $speakers[(int)$s['id']] = [
                'name' => trim(trim((string)$s['first_name']) . ' ' . trim((string)$s['last_name'])),
                'title' => $s['title'],
            ];
        }
        $namesByTalk = [];
        foreach ($talkSpeakers as $ts) {
            $sid = (int)$ts['speaker_id'];
            if (isset($speakers[$sid])) $namesByTalk[(int)$ts['talk_id']][] = $speakers[$sid]['name'];
        }

        $rows = [];
        $talkStats = [];
        $total = 0;
        $rated = 0;
        foreach ($talks as $i => $t) {
            $tid = (int)$t['id'];
            $s = self::stats($dist[$tid] ?? []);
            $talkStats[$tid] = $s;
            $total += $s['votes'];
            if ($s['votes'] > 0) $rated++;
            $rows[] = [
                'id' => $tid, 'order' => $i, 'title' => (string)$t['title'],
                'speakers' => implode(', ', $namesByTalk[$tid] ?? []),
                'room' => $t['room'], 'day' => self::dayLabel($t['day_label'], $t['day_date']),
                'time' => self::timeRange($t['starts_at'], $t['ends_at']),
                'stats' => $s,
            ];
        }
        return [
            'talks' => $rows,
            'speakers' => self::speakerRanking($talkStats, $talkSpeakers, $speakers),
            'total_votes' => $total,
            'voters' => (int)($voters[0]['n'] ?? 0),
            'rated_talks' => $rated,
        ];
    }

    private static function dayLabel(?string $label, ?string $date): string
    {
        $d = ($date !== null && strlen($date) >= 10) ? substr($date, 8, 2) . '.' . substr($date, 5, 2) : '';
        return trim(trim((string)$label) . ' ' . $d);
    }

    private static function timeRange(?string $start, ?string $end): string
    {
        $hm = static fn(?string $v): string => ($v !== null && strlen($v) >= 16) ? substr($v, 11, 5) : '';
        return trim($hm($start) . ($hm($end) !== '' ? ' do ' . $hm($end) : ''));
    }

    // ------------------------------------------------------------ CSV (Excel PL)

    /** Liczba z przecinkiem dziesietnym (Excel PL), pusto gdy brak. */
    public static function num(?float $v, int $decimals = 1): string
    {
        return $v === null ? '' : number_format($v, $decimals, ',', '');
    }

    /** Tekst do komorki CSV: neutralizuje formuly (=, +, -, @, tab, CR) apostrofem. */
    public static function csvCell(?string $s): string
    {
        $s = (string)$s;
        return ($s !== '' && strpbrk($s[0], "=+-@\t\r") !== false) ? "'" . $s : $s;
    }

    public static function csvTalks(array $rows): array
    {
        $out = [array_merge(
            ['Tytuł', 'Prelegenci', 'Sala', 'Dzień', 'Godzina', 'Liczba głosów', 'Średnia', 'Mediana', 'Mała próba'],
            array_map(static fn(int $s): string => 'Ocena ' . $s, range(self::SCORE_MIN, self::SCORE_MAX))
        )];
        foreach ($rows as $r) {
            $s = $r['stats'];
            $out[] = array_merge([
                self::csvCell($r['title']), self::csvCell($r['speakers']), self::csvCell($r['room']),
                self::csvCell($r['day']), self::csvCell($r['time']),
                (string)$s['votes'], self::num($s['avg']), self::num($s['median']),
                $s['votes'] === 0 ? '' : ($s['small'] ? 'tak' : 'nie'),
            ], array_map('strval', array_values($s['dist'])));
        }
        return $out;
    }

    public static function csvSpeakers(array $rows): array
    {
        $out = [['Miejsce', 'Prelegent', 'Tytuł', 'Liczba prelekcji', 'Liczba głosów', 'Średnia ważona', 'Mała próba']];
        foreach ($rows as $i => $r) {
            $out[] = [
                (string)($i + 1), self::csvCell($r['name']), self::csvCell($r['title']),
                (string)$r['talks'], (string)$r['votes'], self::num($r['avg'], 2),
                $r['votes'] === 0 ? '' : ($r['small'] ? 'tak' : 'nie'),
            ];
        }
        return $out;
    }
}
