#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -ne 1 || ! "$1" =~ ^[0-9a-f]{40}$ ]]; then
    echo "Usage: $0 <40-character git commit SHA>" >&2
    exit 2
fi

SHA=$1
APP_ROOT=${APP_ROOT:-/var/www/taskify}
RELEASES="$APP_ROOT/releases"
RELEASE="$RELEASES/$SHA"
SHARED="$APP_ROOT/shared"
SOURCE=${GITHUB_WORKSPACE:?GITHUB_WORKSPACE is required}
PREVIOUS=$(readlink "$APP_ROOT/current" 2>/dev/null || true)
cd /

if [[ -d "$RELEASE" && "$PREVIOUS" == "$RELEASE" ]]; then
    curl --fail --silent --show-error --resolve taskify.click:443:127.0.0.1 https://taskify.click/health
    echo "Release $SHA is already active."
    exit 0
fi
if [[ -e "$RELEASE" ]]; then
    echo "Release path already exists but is not active: $RELEASE" >&2
    exit 1
fi

mkdir -p "$RELEASES" "$SHARED/storage/app" "$SHARED/storage/framework/cache/data" \
    "$SHARED/storage/framework/sessions" "$SHARED/storage/framework/views" \
    "$SHARED/storage/logs" "$SHARED/bootstrap-cache"
mkdir "$RELEASE"
tar -C "$SOURCE" \
    --exclude=.git --exclude=.env --exclude=vendor --exclude=node_modules \
    --exclude=storage/logs --exclude=storage/framework/cache \
    --exclude=storage/framework/sessions --exclude=storage/framework/views \
    -cf - . | tar -C "$RELEASE" -xf -

ln -s "$SHARED/.env" "$RELEASE/.env"
rm -rf "$RELEASE/storage"
ln -s "$SHARED/storage" "$RELEASE/storage"
if [[ -d "$RELEASE/bootstrap/cache" && ! -L "$RELEASE/bootstrap/cache" ]]; then
    [[ ! -e "$RELEASE/bootstrap/cache/.gitignore" ]] || unlink "$RELEASE/bootstrap/cache/.gitignore"
    rmdir "$RELEASE/bootstrap/cache"
fi
ln -s "$SHARED/bootstrap-cache" "$RELEASE/bootstrap/cache"

composer install --working-dir="$RELEASE" --no-dev --no-interaction \
    --prefer-dist --optimize-autoloader --no-progress
php "$RELEASE/artisan" migrate --force
php "$RELEASE/artisan" config:cache
php "$RELEASE/artisan" route:cache
php "$RELEASE/artisan" view:cache

ln -s "$RELEASE" "$APP_ROOT/current.next"
mv -Tf "$APP_ROOT/current.next" "$APP_ROOT/current"

if ! curl --fail --silent --show-error --max-time 20 \
    --resolve taskify.click:443:127.0.0.1 https://taskify.click/health; then
    if [[ -n "$PREVIOUS" ]]; then
        ln -s "$PREVIOUS" "$APP_ROOT/current.rollback"
        mv -Tf "$APP_ROOT/current.rollback" "$APP_ROOT/current"
    fi
    echo "Local health check failed; current release was rolled back." >&2
    exit 1
fi

find "$RELEASES" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %p\n' \
    | sort -rn | awk 'NR > 5 {print $2}' | while IFS= read -r old_release; do
        [[ "$old_release" == "$RELEASE" ]] || rm -rf -- "$old_release"
    done

echo "Deployed $SHA successfully."
