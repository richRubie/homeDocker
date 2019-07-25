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
* change hostname
    https://geek-university.com/raspberry-pi/change-raspberry-pis-hostname/


* install docker
    https://blog.alexellis.io/getting-started-with-docker-on-raspberry-pi/

* install docker compose
    * prerequisite - had to try lots of things so this may not be everything
        sudo apt-get install build-essential libssl-dev libffi-dev python-dev
        sudo pip3 install cffi        
    * install docker
        https://stevenbreuls.com/2019/01/install-docker-on-raspberry-pi/

* install docker-compose as container - not working
    https://medium.freecodecamp.org/the-easy-way-to-set-up-docker-on-a-raspberry-pi-7d24ced073ef



---- not sure about the bits below here

3. install git
sudo apt install git
