# Automatic k3sup join NODE
Script to automatically join new nodes to the k3s cluster with k3sup and terraform.

> You will need to setup "output node_ips and node_names" in your terraform config (example with hetzner cloud):
```terraform
output "node_ips" {
  value = concat(
    #cloud_resource.cluster_name[*].ipv4_address,
    hcloud_server.k8s_worker_node[*].ipv4_address,
  )
}

output "node_names" {
  value = concat(
    #cloud_resource.cluster_name[*].name,
    hcloud_server.k8s_worker_node[*].name,
  )
}
```

## Prerequisites
- terraform
- jq
- kubectl
- k3sup

## How does it work?
1. Script will list current node_ips and node_names.
2. Will apply terraform configs.
3. Grab new node_ips and node_names after terraform apply.
4. Then will automatically join new nodes (which we get from comparing old IP list with new IP list) to the cluster.
5. Lastly will set kubernetes labels.

> It will get the token from ./token file - USE DIFFERENT METHOD!!!

## How to start

```bash
chmod +x deploy_new_nodes.sh
./deploy_new_nodes.sh
```
