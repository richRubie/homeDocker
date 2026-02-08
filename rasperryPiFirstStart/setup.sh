#!/bin/bash

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
