#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
COMPOSE_DIR="$SCRIPT_DIR/../certbot"
MARKER="$SCRIPT_DIR/../secrets/cert/last-copied.txt"

if [ -f "$MARKER" ]; then
    BEFORE=$(sha256sum "$MARKER")
else
    BEFORE=""
fi

cd "$COMPOSE_DIR"
if ! /usr/bin/docker compose up --abort-on-container-exit --exit-code-from certbot; then
    echo "Certbot failed; certificate consumers were not restarted." >&2
    exit 1
fi

if [ ! -f "$MARKER" ]; then
    echo "Certbot completed, but no certificate marker was found." >&2
    exit 1
fi

AFTER=$(sha256sum "$MARKER")
if [ "$BEFORE" = "$AFTER" ]; then
    echo "No certificates were renewed; no containers restarted."
    exit 0
fi

CONTAINERS=$(/usr/bin/docker ps -q --filter label=com.github.richr.cert-reload=true)
if [ -n "$CONTAINERS" ]; then
    echo "$CONTAINERS" | xargs /usr/bin/docker restart
    echo "Restarted certificate-dependent containers."
else
    echo "Certificates renewed, but no labelled containers were running."
fi