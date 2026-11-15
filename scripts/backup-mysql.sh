#!/usr/bin/env bash
set -Eeuo pipefail

BACKUP_DIR=${BACKUP_DIR:-/var/backups/taskify}
MYSQL_DEFAULTS_FILE=${MYSQL_DEFAULTS_FILE:-/etc/taskify/backup.cnf}
LOG_FILE=${BACKUP_LOG_FILE:-/var/log/taskify/backup.log}
RETENTION_DAYS=${RETENTION_DAYS:-7}
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
FINAL_FILE="$BACKUP_DIR/taskify-$STAMP.sql.gz"
TEMP_FILE=$(mktemp "$BACKUP_DIR/.taskify-$STAMP.XXXXXX.tmp")
ERROR_FILE=$(mktemp "$BACKUP_DIR/.taskify-$STAMP.XXXXXX.err")
cd /

log() {
    printf '%s %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$*" >> "$LOG_FILE"
}

cleanup() {
    status=$?
    if [[ -e "$TEMP_FILE" ]]; then
        unlink "$TEMP_FILE"
    fi
    if [[ -e "$ERROR_FILE" ]]; then
        unlink "$ERROR_FILE"
    fi
    if (( status != 0 )); then
        log "ERROR backup failed (exit=$status); incomplete output removed"
    fi
    exit "$status"
}
trap cleanup EXIT

if [[ ! -r "$MYSQL_DEFAULTS_FILE" ]]; then
    log "ERROR protected MySQL defaults file is missing or unreadable"
    exit 1
fi

mysqldump --defaults-extra-file="$MYSQL_DEFAULTS_FILE" --no-tablespaces \
    --single-transaction --routines --triggers --events --hex-blob taskify \
    2>"$ERROR_FILE" | gzip -c > "$TEMP_FILE"
if [[ -s "$ERROR_FILE" ]]; then
    log "ERROR mysqldump reported a warning or error; incomplete output removed"
    exit 1
fi
gzip -t "$TEMP_FILE"
if [[ ! -s "$TEMP_FILE" ]]; then
    log "ERROR backup output is empty"
    exit 1
fi
if ! gzip -dc "$TEMP_FILE" | grep -q 'CREATE TABLE'; then
    log "ERROR backup has no table definitions; incomplete output removed"
    exit 1
fi

chmod 0600 "$TEMP_FILE"
mv -- "$TEMP_FILE" "$FINAL_FILE"
find "$BACKUP_DIR" -maxdepth 1 -type f -name 'taskify-*.sql.gz' \
    -mmin "+$((RETENTION_DAYS * 1440))" -delete
log "OK backup created: $(basename "$FINAL_FILE")"
