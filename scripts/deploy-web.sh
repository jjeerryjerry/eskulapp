#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# deploy-web.sh - wysyla dedykowany CMS + theme WP na cyber-folks (edu-serwer).
#   web/cms/panel/  -> <DOCROOT>/panel/           (panel admina)
#   web/cms/api/    -> <DOCROOT>/api/             (publiczne API dla apki)
#   web/cms/_app/   -> <DOCROOT>/_app/            (kod wspolny; deny w .htaccess)
#   web/wp-theme/eskulapp/ -> <DOCROOT>/wp-content/themes/eskulapp/
#
# WordPress (rdzen) instalujemy osobno przez wp-cli na serwerze; ten skrypt
# NIE rusza rdzenia WP ani root .htaccess (rsync per-podkatalog).
# Sekrety (_app/.env) i logi zostaja na serwerze.
#
# Wymaga w .env: DEPLOY_SSH_HOST, DEPLOY_DOCROOT (+ opcj. DEPLOY_DOMAIN).
# Uzycie:  bash scripts/deploy-web.sh
# ---------------------------------------------------------------------------
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
[[ -f .env ]] || { echo "BLAD: brak .env"; exit 1; }
set -a; . ./.env; set +a
: "${DEPLOY_SSH_HOST:?ustaw DEPLOY_SSH_HOST}"
: "${DEPLOY_DOCROOT:?ustaw DEPLOY_DOCROOT}"
SSH="ssh -F $HOME/.ssh/config"
R="$DEPLOY_SSH_HOST:$DEPLOY_DOCROOT"

$SSH "$DEPLOY_SSH_HOST" "mkdir -p '$DEPLOY_DOCROOT/panel' '$DEPLOY_DOCROOT/api' '$DEPLOY_DOCROOT/_app' '$DEPLOY_DOCROOT/wp-content/themes'"

echo "[1/4] _app (kod wspolny; zachowuje .env i leady)"
rsync -avz --delete --exclude '.env' --exclude 'leads.log' -e "$SSH" web/cms/_app/ "$R/_app/"
echo "[2/4] panel"
rsync -avz --delete -e "$SSH" web/cms/panel/ "$R/panel/"
echo "[3/4] api"
rsync -avz --delete -e "$SSH" web/cms/api/ "$R/api/"
echo "[4/4] theme WP"
rsync -avz --delete -e "$SSH" web/wp-theme/eskulapp/ "$R/wp-content/themes/eskulapp/"

echo "GOTOWE."
echo "  https://${DEPLOY_DOMAIN:-eskulapp.pl}/                 (front WordPress)"
echo "  https://${DEPLOY_DOMAIN:-eskulapp.pl}/panel/logowanie  (panel admina)"
echo "  https://${DEPLOY_DOMAIN:-eskulapp.pl}/api/health"
echo "  https://${DEPLOY_DOMAIN:-eskulapp.pl}/api/public/events/FND2027/bundle"
