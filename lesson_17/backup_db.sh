#!/bin/bash

BACKUP_DIR="/var/backups/carss"
DB_NAME="autos"
DB_USER="postgres"

mkdir -p "$BACKUP_DIR"

FILE_NAME="$BACKUP_DIR/${DB_NAME}_$(date +%Y-%m-%d_%H-%M-%S).sql"

export PGPASSWORD="postgres"
pg_dump -U "$DB_USER" -h 127.0.0.1 "$DB_NAME" > "$FILE_NAME"

find "$BACKUP_DIR" -type f -name "*.sql" -mtime +7 -delete

echo "Backup created: $FILE_NAME"

