#!/usr/bin/env bash
set -e

ROOT_DIR=~mc

if [ $# -lt 2 ]; then
    echo "Usage: MCBErestorebackup.sh <server dir> <backup zip file>"
    exit 1
fi

if [ ! -d "$ROOT_DIR/$1" ]; then
    echo "$ROOT_DIR/$1 not found"
    exit 2
fi

SERVICE=$1
SERVICE_DIR="$ROOT_DIR/$SERVICE"
TEST_SERVICE_OWNER=$(find "$SERVICE_DIR" -maxdepth 0 -user "$(id -u)")
if [ ! -n "$TEST_SERVICE_OWNER" ]; then
    OWNER=$(find "$SERVICE_DIR" -maxdepth 0 -printf '%u')
    echo "This script must be run by the owner of $SERVICE_DIR, $OWNER"
fi


if [ ! -f "$2" ]; then
    echo "$2 not found"
    exit 3
fi

ZIP=$2

TMP=$(mktemp -t -d 'MCBErestore.XXX')
unzip "$ZIP" -d "$TMP"
LEVEL_NAME=$(ls "$TMP")

# workaround for backups missing 'CURRENT' file from db
if [ ! -f "$TMP/$LEVEL_NAME/db/CURRENT" ]; then
        (cd "$TMP/$LEVEL_NAME/db" && find . -maxdepth 1 -name 'MANIFEST*' -printf '%P\n' | tail -n1 > CURRENT)
fi

systemctl stop "mcbe@$SERVICE.service"
WORLD_DIR="$SERVICE_DIR/worlds"
DATE_PART=$(date +%Y/%b/%d_%H-%M.zip)
TARGET_FILE="$ROOT_DIR/backup_dir/${SERVICE}_Backups/${LEVEL_NAME}_Backups/$DATE_PART"
(cd "$WORLD_DIR"; sudo zip -r "$TARGET_FILE" "$LEVEL_NAME")
cp -a "$TMP/$LEVEL_NAME" "$WORLD_DIR/"
systemctl start "mcbe@$SERVICE.service"

rm -r "$TMP"
