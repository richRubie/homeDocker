sudo cp -RL ~/homeDocker/certbot/volumes/etc/live/rubie-todd.uk ~/certStaging
sudo chown -R pi:pi ~/certStaging/
mv ~/certStaging/rubie-todd.uk/* ~/certStaging/
rmdir ~/certStaging/rubie-todd.uk
cat ~/certStaging/privkey.pem ~/certStaging/cert.pem > ~/certStaging/combined.pem
mkdir ~/homeDocker/secrets/certArchive/$(date +"%Y-%m-%d")
mv ~/homeDocker/secrets/cert/* ~/homeDocker/secrets/certArchive/$(date +"%Y-%m-%d")
mv ~/certStaging/* ~/homeDocker/secrets/cert