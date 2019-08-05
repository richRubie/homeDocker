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

DEBIAN
* install docker
    https://blog.alexellis.io/getting-started-with-docker-on-raspberry-pi/
* install docker compose
    * prerequisite - had to try lots of things so this may not be everything
        sudo apt-get install build-essential libssl-dev libffi-dev python-dev
        sudo apt-get install python3-pip
        sudo pip3 install cffi        
    * install docker
        https://stevenbreuls.com/2019/01/install-docker-on-raspberry-pi/
UBUNTU
* install docker
    sudo apt-get install docker docker-compose 
    https://docs.docker.com/install/linux/docker-ce/ubuntu/
    
3. install git
sudo apt-get install git
git clone https://github.com/richRubie/homeDocker


UBUNTU 19

WIFI
https://askubuntu.com/questions/1143287/how-to-setup-of-raspberry-pi-3-onboard-wifi-for-ubuntu-server-18-04

turn off  - systemd-resolved
https://askubuntu.com/questions/907246/how-to-disable-systemd-resolved-in-ubuntu

USEFULL LINUX COMMANDS

check ports
sudo netstat -plnt