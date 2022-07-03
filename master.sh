#!/bin/bash

read -p "Enter node name [master-node]: " NODE_NAME
export NODE_NAME=${NODE_NAME:-master-node}

read -p "Enter nodes IP addresses separated by comma: " IP_STRING
export IP_STRING

function read_ip_array() {
  readarray -td, IP_ARRAY <<<"$IP_STRING,";
  unset 'IP_ARRAY[-1]';
  declare -p IP_ARRAY;
}

export -f read_ip_array

source <(wget -qO- https://raw.githubusercontent.com/risenforces/rancher-bootstrap/main/prepare.sh)
