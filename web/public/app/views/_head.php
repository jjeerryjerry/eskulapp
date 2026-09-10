<?php /** @var string|null $title */ ?>
<!doctype html>
<html lang="pl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title><?= isset($title) ? e($title) . ' · Eskulapp' : 'Eskulapp, jeden identyfikator na eventy medyczne' ?></title>
<meta name="description" content="Eskulapp, agenda, prelegenci, partnerzy, mapa i przypomnienia na konferencje medyczne. Dołącz do wydarzenia jednym kodem, działa też offline.">
<meta property="og:title" content="Eskulapp, Twój identyfikator na każdy event medyczny">
<meta property="og:description" content="Dołącz do wydarzenia jednym kodem. Agenda, prelegenci, partnerzy, mapa, zawsze przy sobie, także offline.">
<meta property="og:type" content="website">
<link rel="icon" href="/assets/logo.svg" type="image/svg+xml">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Sora:wght@400;600;700;800&family=Inter:wght@400;500;600&display=swap">
<link rel="stylesheet" href="/assets/styles.css">
</head>
<body>
