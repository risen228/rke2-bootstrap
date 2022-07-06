# Rancher bootstrap

Script toolbox for Rancher installation on Ubuntu 18.04

## Set up load balancer

Execute command under the `root` user:

```sh
source <(wget -qO- https://raw.githubusercontent.com/risenforces/rancher-bootstrap/main/balancer.sh)
```

Answer the questions and wait for command to be finished.

Later, when you add new `server` node, navigate to `/etc/nginx/nginx.conf` and add a new `server ...` line in all sections.

## Set up master node

Execute command under the `root` user:

```sh
source <(wget -qO- https://raw.githubusercontent.com/risenforces/rancher-bootstrap/main/master.sh)
```

Answer the questions and wait for command to be finished.

### Accessing `server` nodes through the load balancer

You need to set `tls-san` option in your rke2 config.

1. Create config if not exists - `touch /etc/rancher/rke2/config.yaml`

2. Edit it - `nano /etc/rancher/rke2/config.yaml`:

   ```yml
   tls-san:
     - your.domain.com
   ```

3. Restart rke2-server - `systemctl restart rke2-server`

## Set up agent node

Execute command under the `root` user:

```sh
source <(wget -qO- https://raw.githubusercontent.com/risenforces/rancher-bootstrap/main/agent.sh)
```

Answer the questions. The master token can be taken from master node's `/var/lib/rancher/rke2/server/node-token` file.

Wait for command to be finished.

## Connect from your terminal

1. Install `kubectl`
2. Copy kubeconfig from master's `/etc/rancher/rke2/rke2.yaml`
3. Paste it inside `~/.kube/config`
4. Replace `127.0.0.1` with your load balancer domain / IP
5. Now you can access the cluster using `kubectl`

