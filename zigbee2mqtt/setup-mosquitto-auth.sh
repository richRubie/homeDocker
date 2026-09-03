#!/usr/bin/env bash
# Ensures the Mosquitto password file and its plaintext credential store exist,
# with the zigbee2mqtt and homeassistant accounts. Safe to run repeatedly.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_DIR="${MOSQUITTO_SECRETS_DIR:-$SCRIPT_DIR/../secrets/mosquitto}"
PASSWD_FILE="$SECRETS_DIR/passwd"
STORE_FILE="$SECRETS_DIR/credentials"
MOSQUITTO_IMAGE="${MOSQUITTO_IMAGE:-eclipse-mosquitto:latest}"
# uid/gid of the mosquitto user inside the broker image
BROKER_UID=1883
BROKER_GID=1883

USERS=(zigbee2mqtt homeassistant)

usage() {
  cat <<'EOF'
Usage: setup-mosquitto-auth.sh [options]

Options:
  --zigbee2mqtt-password PASSWORD    password for the zigbee2mqtt account
  --homeassistant-password PASSWORD  password for the homeassistant account
  -h, --help                         show this help

Passwords may also be supplied through the ZIGBEE2MQTT_MQTT_PASSWORD and
HOMEASSISTANT_MQTT_PASSWORD environment variables, which keeps them out of the
process list. A password that is not supplied is reused from the credential
store, or generated when the account does not exist yet.
EOF
}

declare -A REQUESTED=()

while [ $# -gt 0 ]; do
  case "$1" in
    --zigbee2mqtt-password)
      [ $# -ge 2 ] || { echo "error: $1 requires a value" >&2; exit 2; }
      REQUESTED[zigbee2mqtt]=$2
      shift 2
      ;;
    --homeassistant-password)
      [ $# -ge 2 ] || { echo "error: $1 requires a value" >&2; exit 2; }
      REQUESTED[homeassistant]=$2
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

: "${REQUESTED[zigbee2mqtt]:=${ZIGBEE2MQTT_MQTT_PASSWORD:-}}"
: "${REQUESTED[homeassistant]:=${HOMEASSISTANT_MQTT_PASSWORD:-}}"

command -v docker >/dev/null || { echo "error: docker is not available" >&2; exit 1; }
command -v openssl >/dev/null || { echo "error: openssl is not available" >&2; exit 1; }

as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

# Colons separate fields in the store and password files, so keep them out of
# generated passwords. base64 output never contains one.
generate_password() {
  openssl rand -base64 24 | tr -d '\n'
}

stored_password() {
  local user=$1 line
  [ -f "$STORE_FILE" ] || return 1
  line=$(as_root grep -m1 -- "^$user:" "$STORE_FILE" 2>/dev/null) || return 1
  printf '%s' "${line#*:}"
}

passwd_has_user() {
  local user=$1
  [ -f "$PASSWD_FILE" ] || return 1
  as_root grep -q -- "^$user:" "$PASSWD_FILE" 2>/dev/null
}

as_root mkdir -p "$SECRETS_DIR"
as_root chmod 700 "$SECRETS_DIR"

changed=0
declare -A PASSWORDS=()

for user in "${USERS[@]}"; do
  requested=${REQUESTED[$user]:-}
  existing=$(stored_password "$user" || true)

  if [ -n "$requested" ]; then
    PASSWORDS[$user]=$requested
    if [ "$requested" = "$existing" ]; then
      echo "unchanged: $user"
    else
      changed=1
      echo "set: $user (supplied)"
    fi
  elif [ -n "$existing" ]; then
    PASSWORDS[$user]=$existing
    echo "unchanged: $user"
  else
    PASSWORDS[$user]=$(generate_password)
    changed=1
    echo "created: $user (generated)"
  fi

  passwd_has_user "$user" || changed=1
done

if [ "$changed" -eq 0 ]; then
  echo "password file already up to date"
else
  work_dir=$(mktemp -d)
  trap 'rm -rf "$work_dir"' EXIT
  chmod 700 "$work_dir"

  for user in "${USERS[@]}"; do
    printf '%s:%s\n' "$user" "${PASSWORDS[$user]}" >>"$work_dir/credentials"
  done
  cp "$work_dir/credentials" "$work_dir/passwd"
  chmod 600 "$work_dir/credentials" "$work_dir/passwd"

  # mosquitto_passwd -U rehashes a plaintext user:password file in place, which
  # avoids passing any password on a command line.
  docker run --rm --user 0:0 -v "$work_dir:/pw" "$MOSQUITTO_IMAGE" \
    mosquitto_passwd -U /pw/passwd

  as_root cp "$work_dir/passwd" "$PASSWD_FILE"
  as_root cp "$work_dir/credentials" "$STORE_FILE"
fi

as_root chown "$BROKER_UID:$BROKER_GID" "$PASSWD_FILE"
as_root chmod 600 "$PASSWD_FILE"
as_root chown "0:0" "$STORE_FILE"
as_root chmod 600 "$STORE_FILE"

echo
echo "password file:     $PASSWD_FILE (${BROKER_UID}:${BROKER_GID}, 0600)"
echo "credential store:  $STORE_FILE (root only, 0600)"
echo
echo "Passwords are not printed. Read them with: sudo cat \"$STORE_FILE\""
echo "After a password change, update ../secrets/zigbee2mqtt/secrets.yaml and the"
echo "Home Assistant MQTT integration, then run: docker compose restart mosquitto"
