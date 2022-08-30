sudo cp -RL ~/homeDocker/certbot/volumes/etc/live/redfoxfactory.co.uk ~/certStaging
sudo chown -R pi:pi ~/certStaging/
mv ~/certStaging/redfoxfactory.co.uk/* ~/certStaging/
rmdir ~/certStaging/redfoxfactory.co.uk
cat ~/certStaging/privkey.pem ~/certStaging/cert.pem > ~/certStaging/combined.pem
mkdir ~/homeDocker/secrets/certArchive/$(date +"%Y-%m-%d")
mv ~/homeDocker/secrets/cert/* ~/homeDocker/secrets/certArchive/$(date +"%Y-%m-%d")
mv ~/certStaging/* ~/homeDocker/secrets/cert