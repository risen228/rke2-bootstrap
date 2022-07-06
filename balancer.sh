CURRENT_HOSTNAME=$(hostname)
read -p "Enter unique hostname [$CURRENT_HOSTNAME]: " HOSTNAME
export HOSTNAME=${HOSTNAME:-$CURRENT_HOSTNAME}

read -p "Enter nodes IP addresses separated by comma: " IP_STRING
readarray -td, IP_ARRAY <<<"$IP_STRING,";
unset 'IP_ARRAY[-1]';
declare -p IP_ARRAY;

apt-get update

apt-mark hold grub-pc
apt-get -y upgrade
apt-mark unhold grub-pc

apt-get install -y curl software-properties-common

##################
## set hostname ##
##################

hostnamectl set-hostname $HOSTNAME
sed -i "s/$CURRENT_HOSTNAME/$HOSTNAME/g" /etc/hosts

##################
## set up nginx ##
##################

add-apt-repository -y ppa:nginx/development
apt-get update
apt-get install -y nginx=1.15.*

function write_upstream {
  tee -a /etc/nginx/nginx.conf << END
    upstream $1 {
        least_conn;
END

  for ip in "${IP_ARRAY[@]}"
  do
    tee -a /etc/nginx/nginx.conf << END
        server $ip:$2 max_fails=3 fail_timeout=5s;
END
  done

  tee -a /etc/nginx/nginx.conf << END
    }

    server {
        listen $2;
        proxy_pass $1;
    }
END
}

function whiteline {
  echo "" >> /etc/nginx/nginx.conf
}

> /etc/nginx/nginx.conf

tee -a /etc/nginx/nginx.conf << END
user www-data;
worker_processes auto;
worker_rlimit_nofile 40000;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 8192;
}

stream {
END

write_upstream "rancher_http" 80
whiteline
write_upstream "rancher_https" 443
whiteline
write_upstream "rancher_register" 9345
whiteline
write_upstream "kubernetes_apiserver" 6443

tee -a /etc/nginx/nginx.conf << END
}
END

# reload nginx
nginx -s reload
systemctl restart nginx.service
