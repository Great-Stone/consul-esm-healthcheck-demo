#!/bin/bash
export HOSTNAME=$(hostname)
export PUBLIC_IPV4=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
export LOCAL_IPV4=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
export INSTANCE_ID=$(curl http://169.254.169.254/latest/meta-data/instance-id)
export INSTANCE_TYPE=$(curl http://169.254.169.254/latest/meta-data/instance-type)
echo ========== Consul License ==========
export CONSUL_LICENSE=${consul_license_txt}

echo ========== Consul Install ==========
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update -y
if [ "$CONSUL_LICENSE" = "" ]; then
  sudo apt install consul -y
else
  sudo apt install consul-enterprise -y
fi
consul version



echo ========== Consul Run ==========
consul agent -server -dev -node=aws-consul-server -bootstrap-expect=1 -client=$LOCAL_IPV4 &