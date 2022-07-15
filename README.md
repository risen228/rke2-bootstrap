# RKE2 bootstrap

Script toolbox for Rancher installation on Ubuntu 18.04

## Set up load balancer

Execute command under the `root` user:

```sh
source <(wget -qO- https://raw.githubusercontent.com/risenforces/rke2-bootstrap/main/balancer.sh)
```

Answer the questions and wait for command to be finished.

You may omit IP question if you want to add server nodes later.

## Set up master node

Execute command under the `root` user:

```sh
source <(wget -qO- https://raw.githubusercontent.com/risenforces/rke2-bootstrap/main/master.sh)
```

Answer the questions and wait for command to be finished.

Then, if you skipped IP question when setting up a load balancer, you should [update the load balancer nginx config](#add-server-node-to-load-balancer) to include a new server node.

## Set up additional server nodes

> **Note**
> You **should** have an odd amount of server nodes (1, 3, 5, etc)

Execute command under the `root` user:

```sh
source <(wget -qO- https://raw.githubusercontent.com/risenforces/rke2-bootstrap/main/server.sh)
```

Answer the questions. The shared token can be taken from master node's `/var/lib/rancher/rke2/server/node-token` file.

Wait for command to be finished.

Then, [update the load balancer nginx config](#add-server-node-to-load-balancer) to include a new server node.

## Add server node to load balancer

- You may specify IP list on initial load balancer set up
- To add server node manually, navigate to `/etc/nginx/nginx.conf` and add new `server` lines in all sections

## Set up agent node

Execute command under the `root` user:

```sh
source <(wget -qO- https://raw.githubusercontent.com/risenforces/rke2-bootstrap/main/agent.sh)
```

Answer the questions. The master token can be taken from master node's `/var/lib/rancher/rke2/server/node-token` file.

Wait for command to be finished.

## Connect from your terminal

1. Install `kubectl`
2. Copy kubeconfig from master's `/etc/rancher/rke2/rke2.yaml`
3. Paste it inside `~/.kube/config`
4. Replace `127.0.0.1` with your load balancer domain / IP
5. Now you can access the cluster using `kubectl`
