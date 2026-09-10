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
