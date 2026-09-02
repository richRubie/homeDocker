# Certbot Automation

This setup manages wildcard certificates for `rubie-todd.uk` using the DNS-Cloudflare plugin.

## 1. Initial Setup
Ensure your Cloudflare credentials are in `../secrets/certbot_credentials/cred.ini`, the certificate output directories exist, and both scripts are executable:
```bash
chmod +x ../rasperryPiFirstStart/certRefresh.sh ../rasperryPiFirstStart/certRenew.sh
```

## 2. Automating Renewal (Cron)
Certbot should check for renewals twice a day. Since we are using Docker Compose, we can trigger the container via the host's crontab.

1. Open crontab: `crontab -e`
2. Add the following line to run at midnight and noon:
```cron
0 0,12 * * * /home/pi/code/homeDocker/rasperryPiFirstStart/certRenew.sh >> /home/pi/code/homeDocker/certbot/volumes/logs/cron.log 2>&1
```
The wrapper runs Certbot, then restarts only containers labelled `com.github.richr.cert-reload=true` when the deploy hook reports that new certificates were copied.

## 3. Testing and Verification
To ensure the system is working as intended before the next 90-day cycle:

### Test the Renewal Logic
Run a "Dry Run" to verify DNS communication and Certbot logic without issuing a real certificate:
```bash
docker compose run --rm certbot renew --dry-run
```

### Test the Deploy Hook
The `certRefresh.sh` script only runs on a **successful** renewal. To test that the script correctly moves files to your `/secrets` folder and generates the `combined.pem`, you can execute it manually inside the container:
```bash
docker compose run --rm --entrypoint /scripts/certRefresh.sh certbot
```

This tests certificate copying only. To test the complete host-side flow, run the wrapper manually:

```bash
../rasperryPiFirstStart/certRenew.sh
```