# Rancher bootstrap

Script toolbox for Rancher installation on Ubuntu 18.04

## Set up load balancer

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

## Set up master node

Execute command under the `root` user:

```sh
source <(wget -qO- https://raw.githubusercontent.com/risenforces/rancher-bootstrap/main/master.sh)
```

The command will ask you to specify the following:

- Hostname - choose the new hostname or remain default by pressing Enter

Wait for command to be finished.

### Accessing `server` nodes through the load balancer

You need to set `tls-san` option in your rke2 config.

1. Create config if not exists - `touch /etc/rancher/rke2/config.yaml`

2. Edit it - `nano /etc/rancher/rke2/config.yaml`:

   ```yml
   tls-san:
     - your.domain.com
   ```

3. Restart rke2-server - `systemctl restart rke2-server`

## Connect from your terminal

1. Install `kubectl`
2. Copy kubeconfig from master's `/etc/rancher/rke2/rke2.yaml`
3. Paste it inside `~/.kube/config`
4. Replace `127.0.0.1` with your load balancer domain / IP
5. Now you can access the cluster using `kubectl`

