#!/bin/bash

apt-get update

apt-mark hold grub-pc
apt-get -y upgrade
apt-mark unhold grub-pc

apt-get install -y gnupg curl software-properties-common

################
## set up ntp ##
################

apt-get install -y ntp
sed -i -e 's/pool 0.ubuntu.pool.ntp.org iburst/server 0.europe.pool.ntp.org/g' /etc/ntp.conf
sed -i -e 's/pool 1.ubuntu.pool.ntp.org iburst/server 1.europe.pool.ntp.org/g' /etc/ntp.conf
sed -i -e 's/pool 2.ubuntu.pool.ntp.org iburst/server 2.europe.pool.ntp.org/g' /etc/ntp.conf
sed -i -e 's/pool 3.ubuntu.pool.ntp.org iburst/server 3.europe.pool.ntp.org/g' /etc/ntp.conf
systemctl restart ntp

##################
## set up nginx ##
##################

add-apt-repository -y ppa:nginx/development
apt-get update
apt-get install -y nginx=1.15.*

# read IP_ARRAY from master.sh user input
read_ip_array

# clear default nginx.conf
> /etc/nginx/nginx.conf

# white nginx.conf beginning
tee -a /etc/nginx/nginx.conf << END
load_module /usr/lib/nginx/modules/ngx_stream_module.so;

worker_processes 4;
worker_rlimit_nofile 40000;

events {
    worker_connections 8192;
}

stream {
    upstream rancher_servers_http {
        least_conn;
END

# write http server line for each node IP
for ip in "${IP_ARRAY[@]}"
do
tee -a /etc/nginx/nginx.conf << END
        server $ip:80 max_fails=3 fail_timeout=5s;
END
done

# write nginx.conf middle
tee -a /etc/nginx/nginx.conf << END
    }
    server {
        listen 80;
        proxy_pass rancher_servers_http;
    }

    upstream rancher_servers_https {
        least_conn;
END

# write https server line for each node IP
for ip in "${IP_ARRAY[@]}"
do
tee -a /etc/nginx/nginx.conf << END
        server $ip:443 max_fails=3 fail_timeout=5s;
END
done

# write nginx.conf ending
tee -a /etc/nginx/nginx.conf << END
    }
    server {
        listen     443;
        proxy_pass rancher_servers_https;
    }

}
END

# reload nginx
nginx -s reload
systemctl restart nginx.service

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
