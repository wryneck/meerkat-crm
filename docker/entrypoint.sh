#!/bin/sh
set -e

# Remap the backend user to the host-provided PUID/PGID so files written to the
# mounted volume (/app/static/photos) get sane ownership, then hand off to
# supervisord (which keeps running as root and drops the backend process to
# appuser via `user=appuser`).
#
# The database lives in MySQL, so there is no SQLite file to chown anymore.

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

# On first startup the mounted directories may be owned by root
if [ -d "$PROFILE_PHOTO_DIR" ] && \
    [ "$(stat -c '%u:%g' "$PROFILE_PHOTO_DIR")" != "$PUID:$PGID" ];
then
    NEEDS_CHOWN=1
fi

if [ "$NEEDS_CHOWN" = "1" ]; then
    chown -R appuser:appgroup "$PROFILE_PHOTO_DIR"
fi

exec "$@"
