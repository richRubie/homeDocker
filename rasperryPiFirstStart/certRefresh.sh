#!/bin/sh
# This script runs inside the Certbot container via --deploy-hook
set -e

SRC="/etc/letsencrypt/live/rubie-todd.uk"
DEST="/secrets/cert"
ARCHIVE="/secrets/certArchive/$(date +"%Y-%m-%d")"
CERT_READERS_GID=$(cat /secrets/.certreaders-gid)

case "$CERT_READERS_GID" in
    *[!0-9]* | '')
        echo "Invalid certreaders GID in /secrets/.certreaders-gid" >&2
        exit 1
        ;;
esac

mkdir -p "$DEST" "$ARCHIVE"
chown root:"$CERT_READERS_GID" "/secrets" "$DEST" "$ARCHIVE"
chmod 750 "/secrets" "$DEST" "$ARCHIVE"

# Archive current certs
cp -f "$DEST"/* "$ARCHIVE"/ 2>/dev/null || true
find "$ARCHIVE" -maxdepth 1 -type f -exec chown root:"$CERT_READERS_GID" {} \; -exec chmod 640 {} \;

# Copy new certs (following symlinks)
cp -L "$SRC/privkey.pem" "$DEST/privkey.pem"
cp -L "$SRC/fullchain.pem" "$DEST/fullchain.pem"
cp -L "$SRC/cert.pem" "$DEST/cert.pem"
cp -L "$SRC/chain.pem" "$DEST/chain.pem"
chown root:"$CERT_READERS_GID" "$DEST/privkey.pem" "$DEST/fullchain.pem" "$DEST/cert.pem" "$DEST/chain.pem"
chmod 640 "$DEST/privkey.pem" "$DEST/fullchain.pem" "$DEST/cert.pem" "$DEST/chain.pem"

# Generate combined files for Pi-hole/Unifi/HA
cat "$SRC/privkey.pem" "$SRC/cert.pem" > "$DEST/combined.pem"
cp "$DEST/combined.pem" "$DEST/pihole.pem"
chown root:"$CERT_READERS_GID" "$DEST/combined.pem" "$DEST/pihole.pem"
chmod 640 "$DEST/combined.pem" "$DEST/pihole.pem"

# This marker is written only after every certificate file has been copied.
printf 'Certificates copied: %s UTC\n' "$(date -u '+%Y-%m-%d %H:%M:%S')" > "$DEST/last-copied.txt"
chown root:"$CERT_READERS_GID" "$DEST/last-copied.txt"
chmod 640 "$DEST/last-copied.txt"

# Install dependencies (needed to talk to docker socket and parse JSON)
apk add --no-cache curl jq

# Restart containers to pick up new certs
# Queries for containers with the label 'com.github.richr.cert-reload=true'
CONTAINER_IDS=$(curl -s --unix-socket /var/run/docker.sock "http://localhost/v1.41/containers/json?filters=%7B%22label%22%3A%5B%22com.github.richr.cert-reload%3Dtrue%22%5D%7D" | jq -r '.[].Id')

for id in $CONTAINER_IDS; do
    echo "Restarting container ID: $id"
    curl -s --unix-socket /var/run/docker.sock -X POST "http://localhost/containers/$id/restart"
done
