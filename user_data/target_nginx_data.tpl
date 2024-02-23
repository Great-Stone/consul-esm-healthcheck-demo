#!/bin/bash
export HOSTNAME=$(hostname)
export PUBLIC_IPV4=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
export LOCAL_IPV4=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
export INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
export INSTANCE_TYPE=$(curl http://169.254.169.254/latest/meta-data/instance-type)

echo ========== Nginx Install ==========
sudo apt update -y
sudo apt install nginx -y

echo ========== Vault Run ==========
sudo systemctl start nginx
sudo systemctl enable nginx