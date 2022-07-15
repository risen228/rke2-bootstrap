#!/bin/bash

CURRENT_HOSTNAME=$(hostname)
read -p "Enter unique hostname [$CURRENT_HOSTNAME]: " HOSTNAME
export HOSTNAME=${HOSTNAME:-$CURRENT_HOSTNAME}

read -p "Enter load balancer hostname: " LOAD_BALANCER_HOSTNAME

source <(wget -qO- https://raw.githubusercontent.com/risenforces/rke2-bootstrap/main/prepare.sh)

##################
## set hostname ##
##################

hostnamectl set-hostname $HOSTNAME
sed -i "s/$CURRENT_HOSTNAME/$HOSTNAME/g" /etc/hosts

################
## setup rke2 ##
################

curl -sfL https://get.rke2.io | sh -
systemctl enable rke2-server.service
systemctl start rke2-server.service

###############################
## add load balancer support ##
###############################

mkdir -p /etc/rancher/rke2

tee -a /etc/rancher/rke2/config.yaml << END
tls-san:
  - $LOAD_BALANCER_HOSTNAME
END

systemctl restart rke2-server.service
