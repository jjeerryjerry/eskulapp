# web/ — Platforma Webowa Eskulapp (backend PHP + CMS)

Tu mieszka **serwis SSO + REST API + Panel CMS** (PHP 8.2 + MySQL, deploy na
cyber-folks). Pusty do czasu decyzji z `docs/ARCHITEKTURA.md §6` (framework,
domena, flow logowania).

Docelowa struktura (propozycja, Slim 4):
```
web/
  public/           # docroot (index.php, .htaccess) — to trafia do public_html
  src/              # kod: Auth, Events, Cms, Middleware, ...
  db/migrations/    # wersjonowane SQL
  config/           # config.php (+ config.local.php gitignored)
  composer.json
  vendor/           # composer install LOKALNIE -> wysyłamy na serwer
```

Deploy: `scripts/deploy-web.sh` (rsync na `edu-serwer`). Sekrety: `../.env`.
