<?php /** @var string|null $title */ ?>
<!doctype html>
<html lang="pl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex, nofollow">
<title><?= isset($title) ? e($title) . ' · Eskulapp CMS' : 'Eskulapp CMS' ?></title>
<link rel="icon" href="<?= ASSET_BASE ?>/logo.svg" type="image/svg+xml">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Sora:wght@400;600;700;800&family=Inter:wght@400;500;600&display=swap">
<link rel="stylesheet" href="<?= ASSET_BASE ?>/styles.css">
</head>
<body>
