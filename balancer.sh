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

function line {
  echo $1 >> /etc/nginx/nginx.conf
}

> /etc/nginx/nginx.conf

line "user www-data;"
line "worker_processes auto;"
line "worker_rlimit_nofile 40000;"
line "pid /run/nginx.pid;"
line "include /etc/nginx/modules-enabled/*.conf;"
line ""
line "events {"
line "    worker_connections 8192;"
line "}"
line ""
line "stream {"

function write_upstream {
  line "    upstream $1"
  line "      least_conn;"
  line ""
  line "      # to add a new server, use the following format:"
  line "      # server <ip>:$2 max_fails=3 fail_timeout=5s;"

  for ip in "${IP_ARRAY[@]}"; do
  line "      server $ip:$2 max_fails=3 fail_timeout=5s;"
  done

  line "    }"
  line ""
  line "    server {"
  line "        listen $2;"
  line "        proxy_pass $1;"
  line "    }"
}

write_upstream "rancher_http" 80
line ""
write_upstream "rancher_https" 443
line ""
write_upstream "rancher_register" 9345
line ""
write_upstream "kubernetes_apiserver" 6443

line "}"

# reload nginx
nginx -s reload
systemctl restart nginx.service
