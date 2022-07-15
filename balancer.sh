CURRENT_HOSTNAME=$(hostname)
read -p "Enter unique hostname [$CURRENT_HOSTNAME]: " HOSTNAME
export HOSTNAME=${HOSTNAME:-$CURRENT_HOSTNAME}

read -p "Enter server nodes IP addresses separated by comma: " IP_STRING
readarray -td, IP_ARRAY <<<"$IP_STRING,";
unset 'IP_ARRAY[-1]';
declare -p IP_ARRAY;

apt-get update
apt-get install -y curl software-properties-common

##################
## set hostname ##
##################

hostnamectl set-hostname $HOSTNAME
sed -i "s/$CURRENT_HOSTNAME/$HOSTNAME/g" /etc/hosts

###################
## install nginx ##
###################

add-apt-repository -y ppa:nginx/development
apt-get update
apt-get install -y nginx=1.15.*

##################
## set up nginx ##
##################

function line {
  echo "$1" >> /etc/nginx/nginx.conf
}

# clear nginx.conf
> /etc/nginx/nginx.conf

line "user www-data;"
line "worker_processes auto;"
line "worker_rlimit_nofile 40000;"
line "pid /run/nginx.pid;"

# enable stream module
line "include /etc/nginx/modules-enabled/*.conf;"

line ""
line "events {"
line "    worker_connections 8192;"
line "}"
line ""
line "stream {"

function write_upstream {
  line "    upstream $1 {"
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

write_upstream "http" 80
line ""
write_upstream "https" 443
line ""
write_upstream "rke2_register" 9345
line ""
write_upstream "k8s_api" 6443

line "}"

# reload nginx
nginx -s reload
systemctl enable nginx.service
systemctl restart nginx.service
