#!/bin/sh
# This script runs inside the Certbot container via --deploy-hook
set -e

SRC="/etc/letsencrypt/live/rubie-todd.uk"
DEST="/secrets/cert"
ARCHIVE="/secrets/certArchive/$(date +"%Y-%m-%d")"

mkdir -p "$ARCHIVE"

# Archive current certs
cp -f "$DEST"/* "$ARCHIVE"/ 2>/dev/null || true

# Copy new certs (following symlinks)
cp -L "$SRC/privkey.pem" "$DEST/privkey.pem"
cp -L "$SRC/fullchain.pem" "$DEST/fullchain.pem"
cp -L "$SRC/cert.pem" "$DEST/cert.pem"
cp -L "$SRC/chain.pem" "$DEST/chain.pem"

# Generate combined files for Pi-hole/Unifi/HA
cat "$SRC/privkey.pem" "$SRC/cert.pem" > "$DEST/combined.pem"
cp "$DEST/combined.pem" "$DEST/pihole.pem"

# Install dependencies (needed to talk to docker socket and parse JSON)
apk add --no-cache curl jq

# Restart containers to pick up new certs
# Queries for containers with the label 'com.github.richr.cert-reload=true'
CONTAINER_IDS=$(curl -s --unix-socket /var/run/docker.sock "http://localhost/v1.41/containers/json?filters=%7B%22label%22%3A%5B%22com.github.richr.cert-reload%3Dtrue%22%5D%7D" | jq -r '.[].Id')

for id in $CONTAINER_IDS; do
    echo "Restarting container ID: $id"
    curl -s --unix-socket /var/run/docker.sock -X POST "http://localhost/containers/$id/restart"
done
