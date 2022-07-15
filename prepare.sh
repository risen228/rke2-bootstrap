#!/bin/bash

apt-get update
apt-get install -y gnupg curl software-properties-common

################
## set up ntp ##
################

apt-get install -y ntp
sed -i -e 's/pool 0.ubuntu.pool.ntp.org iburst/server 0.europe.pool.ntp.org/g' /etc/ntp.conf
sed -i -e 's/pool 1.ubuntu.pool.ntp.org iburst/server 1.europe.pool.ntp.org/g' /etc/ntp.conf
sed -i -e 's/pool 2.ubuntu.pool.ntp.org iburst/server 2.europe.pool.ntp.org/g' /etc/ntp.conf
sed -i -e 's/pool 3.ubuntu.pool.ntp.org iburst/server 3.europe.pool.ntp.org/g' /etc/ntp.conf

systemctl enable ntp
systemctl restart ntp

######################################
## set up open-iscsi (for longhorn) ##
######################################

apt-get install -y open-iscsi
systemctl enable iscsid
systemctl start iscsid

##########
## misc ##
##########

# disable swap
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# fix "/proc/sys/net/bridge/bridge-nf-call-iptables does not exist"
modprobe br_netfilter
echo "br_netfilter" > /etc/modules-load.d/br_netfilter.conf

# fix "/proc/sys/net/ipv4/ip_forward contents are not set to 1"
echo 1 > /proc/sys/net/ipv4/ip_forward
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
