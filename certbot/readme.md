# Certbot Automation

This setup manages wildcard certificates for `rubie-todd.uk` using the DNS-Cloudflare plugin.

## 1. Initial Setup
Ensure your Cloudflare credentials are in `../secrets/certbot_credentials/cred.ini` and the `certRefresh.sh` script is executable:
```bash
chmod +x ../rasperryPiFirstStart/certRefresh.sh
```

## 2. Automating Renewal (Cron)
Certbot should check for renewals twice a day. Since we are using Docker Compose, we can trigger the container via the host's crontab.

1. Open crontab: `crontab -e`
2. Add the following line to run at midnight and noon:
```cron
0 0,12 * * * cd /home/pi/code/homeDocker/certbot && /usr/bin/docker compose up --abort-on-container-exit >> ./volumes/logs/cron.log 2>&1
```
*Note: `--abort-on-container-exit` ensures the task finishes cleanly after Certbot completes its check.*

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