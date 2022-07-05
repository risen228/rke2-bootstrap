# Rancher bootstrap

Script toolbox for Rancher installation on Ubuntu 18.04

## Usage

### On load balancer server

Execute command under the `root` user:

```sh
source <(wget -qO- https://raw.githubusercontent.com/risenforces/rancher-bootstrap/main/balancer.sh)
```

The command will ask you to specify the following:

- Hostname - choose the load balancer domain or remain default by pressing Enter

- All `server` nodes IPs divided by comma (including master)  
  For example: `1.1.1.1,2.2.2.2,3.3.3.3`

Wait for command to be finished.

Later, when you add new `server` node, navigate to `/etc/nginx/nginx.conf` and add a new `server ...` line in all sections.

### On master node

Execute command under the `root` user:

```sh
source <(wget -qO- https://raw.githubusercontent.com/risenforces/rancher-bootstrap/main/master.sh)
```

The command will ask you to specify the following:

- Hostname - choose the new hostname or remain default by pressing Enter

Wait for command to be finished.