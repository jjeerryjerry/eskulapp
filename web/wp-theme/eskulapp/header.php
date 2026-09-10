<?php if (!defined('ABSPATH')) exit; ?><!doctype html>
<html <?php language_attributes(); ?>>
<head>
<meta charset="<?php bloginfo('charset'); ?>">
<meta name="viewport" content="width=device-width, initial-scale=1">
<link rel="icon" href="<?php echo esc_url(get_template_directory_uri()); ?>/assets/logo.svg" type="image/svg+xml">
<?php wp_head(); ?>
</head>
<body <?php body_class(); ?>>
<nav class="nav"><div class="wrap nav-inner">
  <a class="nav-brand" href="<?php echo esc_url(home_url('/')); ?>">
    <?php include get_template_directory() . '/parts/logo.php'; ?>Eskulapp
  </a>
  <div class="nav-links">
    <a href="#dla-uczestnika">Dla uczestnika</a>
    <a href="#funkcje">Funkcje</a>
    <a href="#kontakt">Dla organizatora</a>
    <a class="btn btn-primary" href="#kontakt">Zapytaj o ofertę</a>
  </div>
</div></nav>
