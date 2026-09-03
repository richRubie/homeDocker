# Zigbee2MQTT setup

## Configure the Zigbee adapter

Run these commands on the Raspberry Pi host to find the adapter:

```sh
ls -l /dev/serial/by-id/
```

The Zigbee adapter is normally listed with a name similar to `usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_*`. Copy the complete path on the left side of the arrow.

Create the local Compose environment file:

```sh
cp example.env .env
```

Edit `.env` and set `ZIGBEE_ADAPTER` to the complete `/dev/serial/by-id/...` path reported by the host. Do not commit `.env`; it is ignored by the repository.

If the directory is empty, reconnect the adapter and check:

```sh
dmesg | tail -30
lsusb
```

## Verify the configuration

From this directory, confirm that Compose resolves the device path:

```sh
docker compose config
```

The resolved configuration should contain the adapter under `zigbee2mqtt.devices`. The Compose file maps the host adapter to `/dev/ttyUSB0` inside the container and does not require `privileged: true`.

Start or recreate Zigbee2MQTT:

```sh
docker compose up -d --force-recreate zigbee2mqtt
docker compose logs -f zigbee2mqtt
```

Confirm the logs show a successful coordinator connection and that existing Zigbee devices remain available. If the adapter is unavailable, check that the host path still exists and that no other process is using the serial device.

## Secure the Mosquitto broker

The broker rejects anonymous clients and listens only on `127.0.0.1`. Both Zigbee2MQTT and Home Assistant run in the host network namespace, so loopback is reachable for them and unreachable from the LAN.

Create the password file on the Raspberry Pi host (run from this directory):

```sh
chmod +x setup-mosquitto-auth.sh
./setup-mosquitto-auth.sh
```

The script is safe to re-run. It creates `../secrets/mosquitto/passwd` owned by uid 1883 with mode 600, adds the `zigbee2mqtt` and `homeassistant` accounts, and keeps the plaintext values in the root-only credential store `../secrets/mosquitto/credentials`. Existing passwords are preserved on subsequent runs.

To set a password yourself instead of generating one, pass it through the environment so it stays out of the process list and shell history:

```sh
ZIGBEE2MQTT_MQTT_PASSWORD='...' HOMEASSISTANT_MQTT_PASSWORD='...' ./setup-mosquitto-auth.sh
```

Read the generated values with `sudo cat ../secrets/mosquitto/credentials`, then record the Zigbee2MQTT credentials in `../secrets/zigbee2mqtt/secrets.yaml`:

```yaml
mqtt_user: zigbee2mqtt
mqtt_password: <generated password>
```

Restart the stack and confirm the broker is not exposed:

```sh
docker compose up -d --force-recreate mosquitto zigbee2mqtt
docker compose logs --tail 50 mosquitto zigbee2mqtt
sudo ss -lntp | grep 1883
```

`ss` should show `127.0.0.1:1883` only. Finally update the Home Assistant MQTT integration (Settings, Devices & services, MQTT, Configure) with host `127.0.0.1` and the `homeassistant` broker credentials.

A LAN listener is only needed if an off-host client uses the broker. In that case uncomment the second listener in `volumes/mosquittoConfig/mosquitto.conf`, set it to the Pi's LAN IP, and add a separate broker account for that client.

