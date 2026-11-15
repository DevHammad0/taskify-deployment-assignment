#!/usr/bin/env bash
set -Eeuo pipefail

LOG_DIR=${LARAVEL_LOG_DIR:-/var/www/taskify/shared/storage/logs}
WARN_LIMIT_BYTES=${WARN_LIMIT_BYTES:-524288000}
COMPRESSED_RETENTION_DAYS=${COMPRESSED_RETENTION_DAYS:-14}
CLEANUP_LOG=${CLEANUP_LOG:-/var/log/taskify/log-cleanup.log}
TODAY="laravel-$(date +%F).log"
cd /

log() {
    printf '%s %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$*" >> "$CLEANUP_LOG"
}

if [[ ! -d "$LOG_DIR" ]]; then
    log "ERROR Laravel log directory does not exist: $LOG_DIR"
    exit 1
fi

while IFS= read -r -d '' file; do
    [[ "$(basename "$file")" == "$TODAY" ]] && continue
    if gzip -n -- "$file"; then
        log "COMPRESSED $(basename "$file")"
    else
        log "ERROR could not compress $(basename "$file")"
        exit 1
    fi
done < <(find "$LOG_DIR" -maxdepth 1 -type f -name 'laravel-*.log' -mmin +1440 -print0)

find "$LOG_DIR" -maxdepth 1 -type f -name 'laravel-*.log.gz' \
    -mmin "+$((COMPRESSED_RETENTION_DAYS * 1440))" -print0 |
while IFS= read -r -d '' file; do
    if unlink "$file"; then
        log "DELETED expired archive $(basename "$file")"
    else
        log "ERROR could not delete $(basename "$file")"
        exit 1
    fi
done

SIZE_BYTES=$(du -sb "$LOG_DIR" | awk '{print $1}')
if (( SIZE_BYTES > WARN_LIMIT_BYTES )); then
    log "WARNING logs folder is ${SIZE_BYTES} bytes (limit ${WARN_LIMIT_BYTES})"
else
    log "OK logs folder is ${SIZE_BYTES} bytes"
fi
