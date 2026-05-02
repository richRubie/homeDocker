sudo cp -RL ~/homeDocker/certbot/volumes/etc/live/rubie-todd.uk ~/certStaging
sudo chown -R pi:pi ~/certStaging/

mv -f ~/certStaging/rubie-todd.uk/* ~/certStaging/
rmdir ~/certStaging/rubie-todd.uk

cat ~/certStaging/privkey.pem ~/certStaging/cert.pem > ~/certStaging/combined.pem

ARCHIVE_DIR=~/homeDocker/secrets/certArchive/$(date +"%Y-%m-%d")
mkdir -p "$ARCHIVE_DIR"

mv -f ~/homeDocker/secrets/cert/* "$ARCHIVE_DIR"/ 2>/dev/null || true
mv -f ~/certStaging/* ~/homeDocker/secrets/cert
