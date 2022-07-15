#!/bin/bash

CURRENT_HOSTNAME=$(hostname)
read -p "Enter unique hostname [$CURRENT_HOSTNAME]: " HOSTNAME
export HOSTNAME=${HOSTNAME:-$CURRENT_HOSTNAME}

read -p "Enter load balancer hostname: " LOAD_BALANCER_HOSTNAME
read -p "Enter shared token: " TOKEN

source <(wget -qO- https://raw.githubusercontent.com/risenforces/rke2-bootstrap/main/prepare.sh)

##################
## set hostname ##
##################

hostnamectl set-hostname $HOSTNAME
sed -i "s/$CURRENT_HOSTNAME/$HOSTNAME/g" /etc/hosts

################
## setup rke2 ##
################

curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" sh -

mkdir -p /etc/rancher/rke2/

tee -a /etc/rancher/rke2/config.yaml << END
server: https://$LOAD_BALANCER_HOSTNAME:9345
token: $TOKEN
END

systemctl enable rke2-agent.service
systemctl start rke2-agent.service
