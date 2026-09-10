<?php
declare(strict_types=1);

/**
 * Bundle eventu dla aplikacji (READ, publiczne).
 * GET /public/events/{code}/bundle -> jeden JSON: event + days + rooms + talks +
 * speakers + partners + map + contacts + news, z updated_at (delta ?since=).
 *
 * Gdy jest DB -> składamy z bazy. Gdy brak DB -> zwracamy demo (FND2027),
 * żeby aplikacja Android miała działający endpoint już teraz (offline-first dev).
 */
final class Bundle
{
    public static function forCode(string $code): ?array
    {
        $code = strtoupper(trim($code));
        $pdo = db();
        if ($pdo !== null) {
            $b = self::fromDb($pdo, $code);
            if ($b !== null) return $b;
            // event nie znaleziony w DB, nie fallbackujemy do demo w produkcji
            return null;
        }
        return self::demo($code);
    }

    private static function fromDb(PDO $pdo, string $code): ?array
    {
        $st = $pdo->prepare("SELECT * FROM events WHERE access_code = ? AND status IN ('published','archived') LIMIT 1");
        $st->execute([$code]);
        $ev = $st->fetch();
        if (!$ev) return null;
        $eid = (int)$ev['id'];
        $q = fn(string $sql) => (function($s) use ($pdo, $eid) {
            $x = $pdo->prepare($s); $x->execute([$eid]); return $x->fetchAll();
        })($sql);
        $days     = $q("SELECT id,date,label,sort FROM event_days WHERE event_id=? ORDER BY sort,date");
        $rooms    = $q("SELECT id,name,sort FROM rooms WHERE event_id=? ORDER BY sort,name");
        $talks    = $q("SELECT id,day_id,room_id,title,abstract,starts_at,ends_at,sort FROM talks WHERE event_id=? ORDER BY starts_at,sort");
        $speakers = $q("SELECT id,first_name,last_name,title,photo_url,bio,sort FROM speakers WHERE event_id=? ORDER BY sort,last_name");
        $partners = $q("SELECT id,name,logo_url,description,tier,booth_location,website,sort FROM partners WHERE event_id=? ORDER BY sort,name");
        $contacts = $q("SELECT id,label,name,phone,email,note,sort FROM contacts WHERE event_id=? ORDER BY sort");
        $news     = $q("SELECT id,type,title,body,link_type,link_ref,pinned,published_at FROM news WHERE event_id=? ORDER BY pinned DESC, published_at DESC");
        $ts = $pdo->prepare("SELECT talk_id,speaker_id FROM talk_speakers ts JOIN talks t ON t.id=ts.talk_id WHERE t.event_id=?");
        $ts->execute([$eid]);
        return [
            'event' => [
                'id' => $eid, 'slug' => $ev['slug'], 'name' => $ev['name'],
                'access_code' => $ev['access_code'], 'is_closed' => (bool)$ev['is_closed'],
                'starts_at' => $ev['starts_at'], 'ends_at' => $ev['ends_at'],
                'venue_name' => $ev['venue_name'], 'city' => $ev['city'],
                'map_image_url' => $ev['map_image_url'], 'map_embed' => $ev['map_embed'],
                'push_topic' => $ev['push_topic'], 'status' => $ev['status'],
                'updated_at' => $ev['updated_at'],
            ],
            'days' => $days, 'rooms' => $rooms, 'talks' => $talks,
            'speakers' => $speakers, 'talk_speakers' => $ts->fetchAll(),
            'partners' => $partners, 'contacts' => $contacts, 'news' => $news,
            'generated_at' => gmdate('c'),
        ];
    }

    /** Demo bundle (bez DB), kod FND2027. */
    private static function demo(string $code): ?array
    {
        if ($code !== 'FND2027') return null;
        return [
            'event' => [
                'id' => 1, 'slug' => 'fnd-2027', 'name' => 'Forum Nefrologii Dziecięcej 2027',
                'access_code' => 'FND2027', 'is_closed' => true,
                'starts_at' => '2027-03-14 09:00:00', 'ends_at' => '2027-03-15 16:00:00',
                'venue_name' => 'Hala Expo', 'city' => 'Warszawa',
                'map_image_url' => null, 'map_embed' => null,
                'push_topic' => 'event_1', 'status' => 'published',
                'updated_at' => '2027-03-14 08:00:00',
            ],
            'days' => [
                ['id' => 1, 'date' => '2027-03-14', 'label' => 'Dzień 1', 'sort' => 0],
                ['id' => 2, 'date' => '2027-03-15', 'label' => 'Dzień 2', 'sort' => 1],
            ],
            'rooms' => [
                ['id' => 1, 'name' => 'Sala A', 'sort' => 0],
                ['id' => 2, 'name' => 'Sala B', 'sort' => 1],
                ['id' => 3, 'name' => 'Sala C', 'sort' => 2],
            ],
            'talks' => [
                ['id' => 1, 'day_id' => 1, 'room_id' => 1, 'title' => 'Sesja inauguracyjna', 'abstract' => null, 'starts_at' => '2027-03-14 09:00:00', 'ends_at' => '2027-03-14 09:45:00', 'sort' => 0],
                ['id' => 2, 'day_id' => 1, 'room_id' => 1, 'title' => 'Nowe wytyczne leczenia 2027', 'abstract' => null, 'starts_at' => '2027-03-14 10:00:00', 'ends_at' => '2027-03-14 10:45:00', 'sort' => 1],
                ['id' => 3, 'day_id' => 1, 'room_id' => 3, 'title' => 'Warsztat USG nerek', 'abstract' => null, 'starts_at' => '2027-03-14 11:00:00', 'ends_at' => '2027-03-14 12:30:00', 'sort' => 2],
            ],
            'speakers' => [
                ['id' => 1, 'first_name' => 'Anna', 'last_name' => 'Kowalska', 'title' => 'prof., Kier. Kliniki Nefrologii WUM', 'photo_url' => null, 'bio' => null, 'sort' => 0],
                ['id' => 2, 'first_name' => 'Jan', 'last_name' => 'Nowak', 'title' => 'prof., CZD Warszawa', 'photo_url' => null, 'bio' => null, 'sort' => 1],
                ['id' => 3, 'first_name' => 'Piotr', 'last_name' => 'Wiśniewski', 'title' => 'dr, USK Wrocław', 'photo_url' => null, 'bio' => null, 'sort' => 2],
            ],
            'talk_speakers' => [
                ['talk_id' => 1, 'speaker_id' => 2],
                ['talk_id' => 2, 'speaker_id' => 1],
                ['talk_id' => 3, 'speaker_id' => 3],
            ],
            'partners' => [
                ['id' => 1, 'name' => 'NefroMed Polska', 'logo_url' => null, 'description' => 'Dializa i terapie nerkozastępcze', 'tier' => 'strategiczny', 'booth_location' => 'Stoisko A1', 'website' => null, 'sort' => 0],
                ['id' => 2, 'name' => 'MedTech Sp. z o.o.', 'logo_url' => null, 'description' => 'Aparatura USG i diagnostyka', 'tier' => 'partner', 'booth_location' => 'Stoisko A3', 'website' => null, 'sort' => 1],
            ],
            'contacts' => [
                ['id' => 1, 'label' => 'Biuro kongresu', 'name' => 'Pol. Tow. Nefrologiczne', 'phone' => '+48 22 123 45 67', 'email' => 'biuro@fnd2027.pl', 'note' => 'pon-pt 9-17', 'sort' => 0],
            ],
            'news' => [
                ['id' => 1, 'type' => 'sala', 'title' => 'Zmiana sali: „Wytyczne 2027”', 'body' => 'Prelekcja przeniesiona z Sali B do Sali A.', 'link_type' => 'talk', 'link_ref' => '2', 'pinned' => 1, 'published_at' => '2027-03-14 09:40:00'],
            ],
            'generated_at' => gmdate('c'),
            '_demo' => true,
        ];
    }
}
