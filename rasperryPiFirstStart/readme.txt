
*. enable ssh by creating ssh file in boot dir
*. OPTIONAL - enable wifi by copying wpa_supplicant.conf
*. change hostname
    https://geek-university.com/raspberry-pi/change-raspberry-pis-hostname/
*. Run below

sudo apt install git
git clone https://github.com/richRubie/homeDocker
cd homeDocker/rasperryPiFirstStart
chmod +x setup.sh
./setup.sh

*. add windows key
        https://www.hanselman.com/blog/HowToUseWindows10sBuiltinOpenSSHToAutomaticallySSHIntoARemoteLinuxMachine.aspx
        run below in windows
        type C:\Users\RichardRubie-Todd\.ssh\id_rsa.pub | ssh pi@HOSTNAME 'cat >> .ssh/authorized_keys'


sudo cp -rL ~/homeDocker/certbot/volumes/etc/live/redfoxfactory.co.uk-0001 ~/certStaging
sudo chown -R pi:pi ~/certStaging/
cd ~/certStaging
cat privkey.pem cert.pem > combined.pem
cp -rL ~/homeDocker/secrets/cert ~/homeDocker/secrets/certArchive/$(date +"%Y-%m-%d")
cp -fR ~/certStaging/* ~/homeDocker/secrets/cert


docker-compose down && docker-compose pull && docker-compose up -d

docker on pi
https://blog.alexellis.io/getting-started-with-docker-on-raspberry-pi/

* Raspbian buster Lite
* enable ssh by creating ssh file in boot dir
* change password
    passwd 
    https://www.raspberrypi.org/documentation/linux/usage/users.md
* Allow auto login to pi
    * create folders for HowToUseWindows10sBuiltinOpenSSHToAutomaticallySSHIntoARemoteLinuxMachine
        https://askubuntu.com/questions/466549/bash-home-user-ssh-authorized-keys-no-such-file-or-directory/466558#466558
        mkdir ~/.ssh
        chmod 700 ~/.ssh
        touch ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/authorized_keys
    * add windows key
        https://www.hanselman.com/blog/HowToUseWindows10sBuiltinOpenSSHToAutomaticallySSHIntoARemoteLinuxMachine.aspx
        run below in windows
        type C:\Users\RichardRubie-Todd\.ssh\id_rsa.pub | ssh X@192.168.1.X 'cat >> .ssh/authorized_keys'
* change hostname
    https://geek-university.com/raspberry-pi/change-raspberry-pis-hostname/

* update
    sudo apt update && sudo apt full-upgrade


* install docker
    https://blog.alexellis.io/getting-started-with-docker-on-raspberry-pi/
* install docker compose
    https://withblue.ink/2020/06/24/docker-and-docker-compose-on-raspberry-pi-os.html
    sudo apt install -y python3-pip libffi-dev
    sudo pip3 install docker-compose
    
3. install git
sudo apt-get install git
git clone https://github.com/richRubie/homeDocker
