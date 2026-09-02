# CUPS

This Compose setup grants CUPS access to one printer device instead of the
entire host USB bus. It also runs without `privileged: true`.

## Configure the printer device

Run these commands on the Raspberry Pi host, not inside the container:

```bash
lsusb
ls -l /dev/bus/usb/*/*
```

Find the USB bus and device number belonging to the printer. For example,
`Bus 001 Device 002` corresponds to `/dev/bus/usb/001/002`.

Copy the example environment file:

```bash
cp example.env .env
```

Edit `.env` and set `CUPS_PRINTER_DEVICE` to the printer's full device path.
The `.env` file is ignored by Git. USB device numbers can change after a
reconnect or reboot, so check the path again if CUPS can no longer access the
printer.

## Start and verify

From this directory, validate the resolved device mapping:

```bash
docker compose config
```

Start CUPS and inspect its logs:

```bash
docker compose up -d --force-recreate
docker compose logs -f cupsd
```

If printing does not work, confirm the device path and check whether the
printer requires DBus access. Do not restore `privileged: true` unless a
specific required function has been identified.