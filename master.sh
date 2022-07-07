#!/bin/bash

CURRENT_HOSTNAME=$(hostname)
read -p "Enter unique hostname [$CURRENT_HOSTNAME]: " HOSTNAME
export HOSTNAME=${HOSTNAME:-$CURRENT_HOSTNAME}

read -p "Enter load balancer hostname (domain): " LOAD_BALANCER_HOSTNAME
read -p "Enter bootstrap password for Rancher: " BOOTSTRAP_PASSWORD
read -p "Enter email for Let's Encrypt notifications: " LETS_ENCRYPT_EMAIL

source <(wget -qO- https://raw.githubusercontent.com/risenforces/rancher-bootstrap/main/prepare.sh)

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

touch /etc/rancher/rke2/config.yaml

tee -a /etc/rancher/rke2/config.yaml << END
tls-san:
  - $LOAD_BALANCER_HOSTNAME
END

systemctl restart rke2-server.service

########################
## install kubernetes ##
########################

curl -LO https://dl.k8s.io/release/v1.23.0/bin/linux/amd64/kubectl
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

while ! test -f "/etc/rancher/rke2/rke2.yaml"; do
  echo "Waiting for rke2/rke2.yaml to be created.."
  sleep 5
done

# create rke2/rke2.yaml -> ~/.kube/config symlink to access cluster using kubectl
mkdir ~/.kube
ln -f /etc/rancher/rke2/rke2.yaml ~/.kube/config

##################
## install helm ##
##################

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm ./get_helm.sh

###########################
## install rancher chart ##
###########################

helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo add jetstack https://charts.jetstack.io
helm repo update

kubectl create namespace cattle-system
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.7.1/cert-manager.crds.yaml

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.7.1

helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=$LOAD_BALANCER_HOSTNAME \
  --set bootstrapPassword=$BOOTSTRAP_PASSWORD \
  --set ingress.tls.source=letsEncrypt \
  --set letsEncrypt.email=$LETS_ENCRYPT_EMAIL \
  --set letsEncrypt.ingress.class=nginx
