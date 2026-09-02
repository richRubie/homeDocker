#!/bin/sh
set -eu

GROUP_NAME="certreaders"
USER_NAME="admin"
SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
SECRETS_DIR="$(dirname "$SCRIPT_DIR")/secrets"
CERT_DIR="$SECRETS_DIR/cert"
CERT_ARCHIVE_DIR="$SECRETS_DIR/certArchive"
GROUP_GID=""

if [ "$(id -u)" -ne 0 ]; then
    echo "Run this script with sudo."
    exit 1
fi

if ! getent group "$GROUP_NAME" >/dev/null; then
    groupadd "$GROUP_NAME"
fi

if ! id -nG "$USER_NAME" | tr ' ' '\n' | grep -qx "$GROUP_NAME"; then
    usermod -aG "$GROUP_NAME" "$USER_NAME"
fi

GROUP_GID=$(getent group "$GROUP_NAME" | cut -d: -f3)
mkdir -p "$CERT_DIR" "$CERT_ARCHIVE_DIR"
chown root:"$GROUP_NAME" "$SECRETS_DIR" "$CERT_DIR" "$CERT_ARCHIVE_DIR"
chmod 750 "$SECRETS_DIR" "$CERT_DIR" "$CERT_ARCHIVE_DIR"
printf '%s\n' "$GROUP_GID" > "$SECRETS_DIR/.certreaders-gid"
chown root:"$GROUP_NAME" "$SECRETS_DIR/.certreaders-gid"
chmod 640 "$SECRETS_DIR/.certreaders-gid"

find "$CERT_DIR" -type f -exec chown root:"$GROUP_NAME" {} \;
find "$CERT_DIR" -type f -exec chmod 640 {} \;

echo "Configured $GROUP_NAME access to certificates. Sign out and back in before using the new group."