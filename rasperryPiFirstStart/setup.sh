#!/bin/bash

sudo apt update -y
sudo apt upgrade -y

# docker - https://docs.docker.com/engine/install/debian/

sudo systemctl start docker

sudo usermod -aG docker admin

sudo reboot
