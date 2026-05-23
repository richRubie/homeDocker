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

# Install curl (needed to talk to docker socket)
apk add --no-cache curl

# Restart containers to pick up new certs
# Ensure these names match your 'container_name' in docker-compose files
for container in unifi pihole home-assistant; do
    echo "Restarting $container..."
    curl --unix-socket /var/run/docker.sock -X POST "http://localhost/containers/$container/restart"
done
