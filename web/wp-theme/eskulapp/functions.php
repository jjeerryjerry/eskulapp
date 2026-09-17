<?php
/**
 * Eskulapp theme (front). Motyw serwuje landing V3; tresc edytowalna w WP.
 * Logowanie i CMS sa POZA WordPressem (dedykowany modul /panel).
 */
if (!defined('ABSPATH')) exit;

add_action('after_setup_theme', function () {
    add_theme_support('title-tag');
    add_theme_support('post-thumbnails');
    add_theme_support('html5', ['style', 'script']);
    register_nav_menus(['primary' => 'Menu glowne']);
});

add_action('wp_enqueue_scripts', function () {
    $ver = wp_get_theme()->get('Version');
    wp_enqueue_style('eskulapp-fonts', 'https://fonts.googleapis.com/css2?family=Sora:wght@400;600;700;800&family=Inter:wght@400;500;600&display=swap', [], null);
    wp_enqueue_style('eskulapp-landing', get_template_directory_uri() . '/assets/landing.css', [], $ver);
    wp_enqueue_script('eskulapp-lead', get_template_directory_uri() . '/assets/lead.js', [], $ver, true);
});

// Adres API dla formularza (lead trafia na kontakt@eskulapp.pl)
add_action('wp_head', function () {
    echo '<meta name="eskulapp-api" content="' . esc_url(home_url('/api')) . '">' . "\n";
});

/* =========================================================================
   SEO (2026-08-19). Meta title/description, canonical, Open Graph, Twitter
   Card, JSON-LD (Organization + SoftwareApplication + FAQPage na froncie).
   Wszystko odwracalne - blok mozna usunac bez wplywu na reszte motywu.
   ========================================================================= */

// 1) Tytul dokumentu na stronie glownej.
add_filter('pre_get_document_title', function ($title) {
    if (is_front_page() || is_home()) {
        return 'Eskulapp - aplikacja na konferencje i eventy medyczne';
    }
    return $title;
});

// 2) Meta description, canonical, OG, Twitter, JSON-LD.
add_action('wp_head', function () {
    $home  = home_url('/');
    $desc  = 'Eskulapp to aplikacja na konferencje i eventy medyczne: agenda, prelegenci, mapa stoisk i powiadomienia. Uczestnik dolacza jednym kodem. Zapytaj o wycene.';
    $title = 'Eskulapp - aplikacja na konferencje i eventy medyczne';
    $ogimg = get_template_directory_uri() . '/assets/og-image.png';

    // Canonical + description tylko na froncie (jedna landing page).
    if (is_front_page() || is_home()) {
        echo '<meta name="description" content="' . esc_attr($desc) . '">' . "\n";
        echo '<link rel="canonical" href="' . esc_url($home) . '">' . "\n";

        // Open Graph
        echo '<meta property="og:type" content="website">' . "\n";
        echo '<meta property="og:site_name" content="Eskulapp">' . "\n";
        echo '<meta property="og:locale" content="pl_PL">' . "\n";
        echo '<meta property="og:title" content="' . esc_attr($title) . '">' . "\n";
        echo '<meta property="og:description" content="' . esc_attr($desc) . '">' . "\n";
        echo '<meta property="og:url" content="' . esc_url($home) . '">' . "\n";
        echo '<meta property="og:image" content="' . esc_url($ogimg) . '">' . "\n";
        echo '<meta property="og:image:width" content="1200">' . "\n";
        echo '<meta property="og:image:height" content="630">' . "\n";

        // Twitter Card
        echo '<meta name="twitter:card" content="summary_large_image">' . "\n";
        echo '<meta name="twitter:title" content="' . esc_attr($title) . '">' . "\n";
        echo '<meta name="twitter:description" content="' . esc_attr($desc) . '">' . "\n";
        echo '<meta name="twitter:image" content="' . esc_url($ogimg) . '">' . "\n";

        // --- JSON-LD ---
        $org = [
            '@context' => 'https://schema.org',
            '@type'    => 'Organization',
            'name'     => 'Eskulapp',
            'url'      => $home,
            'logo'     => get_template_directory_uri() . '/assets/logo.svg',
            'email'    => 'kontakt@eskulapp.pl',
            'description' => 'Aplikacja na konferencje i eventy medyczne dla organizatorow i uczestnikow.',
        ];

        $app = [
            '@context'            => 'https://schema.org',
            '@type'               => 'SoftwareApplication',
            'name'                => 'Eskulapp',
            'applicationCategory' => 'BusinessApplication',
            'operatingSystem'     => 'Android',
            'url'                 => $home,
            'description'         => 'Aplikacja eventowa dla uczestnikow konferencji medycznych: agenda, prelegenci, mapa stoisk, powiadomienia push, tryb offline. Uczestnik pobiera aplikacje z Google Play i dolacza jednym kodem wydarzenia.',
            'offers'              => [
                '@type'         => 'Offer',
                'price'         => '0',
                'priceCurrency' => 'PLN',
                'description'   => 'Wycena zalezy od skali wydarzenia. Zapytaj o oferte.',
            ],
        ];

        $faq = [
            '@context'   => 'https://schema.org',
            '@type'      => 'FAQPage',
            'mainEntity' => [
                ['@type' => 'Question', 'name' => 'Czy uczestnik musi instalowac aplikacje ze sklepu?', 'acceptedAnswer' => ['@type' => 'Answer', 'text' => 'Tak - uczestnik pobiera bezplatna aplikacje Eskulapp z Google Play, a nastepnie dolacza do wydarzenia jednym kodem (np. EVENT2026), bez zakladania konta. Caly program ma wtedy zawsze przy sobie, takze offline.']],
                ['@type' => 'Question', 'name' => 'Ile trwa wdrozenie?', 'acceptedAnswer' => ['@type' => 'Answer', 'text' => 'Standardowo przygotowujemy aplikacje na podstawie przeslanej agendy i listy prelegentow. Termin uruchomienia ustalamy pod date wydarzenia, tak aby wszystko bylo gotowe przed pierwszym dniem konferencji.']],
                ['@type' => 'Question', 'name' => 'Czy Eskulapp nadaje sie do kongresu wielodniowego i wielosalowego?', 'acceptedAnswer' => ['@type' => 'Answer', 'text' => 'Tak. Agenda obsluguje wiele dni, wiele sal i rownoleglych sciezek tematycznych, a uczestnik filtruje program po dniu, sali i temacie.']],
                ['@type' => 'Question', 'name' => 'Co z danymi uczestnikow i RODO?', 'acceptedAnswer' => ['@type' => 'Answer', 'text' => 'Dane uczestnikow przetwarzamy zgodnie z RODO, a hosting utrzymujemy w Unii Europejskiej. Dostep do wydarzenia jest zamkniety - otwiera go tylko indywidualny kod eventu.']],
                ['@type' => 'Question', 'name' => 'Czy aplikacja dziala bez internetu?', 'acceptedAnswer' => ['@type' => 'Answer', 'text' => 'Tak. Caly program zapisuje sie na urzadzeniu i dziala offline, wiec uczestnik korzysta z agendy nawet bez zasiegu w hali konferencyjnej.']],
                ['@type' => 'Question', 'name' => 'Ile kosztuje aplikacja na konferencje?', 'acceptedAnswer' => ['@type' => 'Answer', 'text' => 'Wycena zalezy od skali wydarzenia i zakresu wdrozenia. Zostaw kontakt - przygotujemy bezplatna wycene dopasowana do Twojej konferencji i pokazemy aplikacje na zywo.']],
            ],
        ];

        $flags = JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES;
        echo '<script type="application/ld+json">' . wp_json_encode($org, $flags) . '</script>' . "\n";
        echo '<script type="application/ld+json">' . wp_json_encode($app, $flags) . '</script>' . "\n";
        echo '<script type="application/ld+json">' . wp_json_encode($faq, $flags) . '</script>' . "\n";
    }
}, 5);
