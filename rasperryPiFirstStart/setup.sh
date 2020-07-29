#!/bin/bash

passwd

# setup auto login
mkdir ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

sudo apt update -y
sudo apt upgrade -y

# docker
curl -sSL https://get.docker.com | sh

sudo systemctl enable docker

sudo systemctl start docker

sudo usermod -aG docker pi

# docker compose
sudo apt install -y python3-pip libffi-dev
sudo pip3 install docker-compose

sudo reboot