#!/bin/sh
set -e

PUID="${PUID:-1001}"
PGID="${PGID:-1001}"

NEEDS_CHOWN=0

if [ "$(id -g appuser)" != "$PGID" ]; then
    groupmod -o -g "$PGID" appgroup
    NEEDS_CHOWN=1
fi

if [ "$(id -u appuser)" != "$PUID" ]; then
    usermod -o -u "$PUID" appuser
    NEEDS_CHOWN=1
fi

# The database now lives in MySQL, so only the photo directory needs to be
# writable by the app user.
if [ -d "$PROFILE_PHOTO_DIR" ] && \
    [ "$(stat -c '%u:%g' "$PROFILE_PHOTO_DIR")" != "$PUID:$PGID" ];
then
    NEEDS_CHOWN=1
fi

if [ "$NEEDS_CHOWN" = "1" ]; then
    chown -R appuser:appgroup /app/data /app/static/photos
fi

exec su-exec appuser:appgroup "$@"
