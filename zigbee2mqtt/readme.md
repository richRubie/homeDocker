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
