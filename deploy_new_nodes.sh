#!/bin/bash

# Load environment variables from .env file
set -a
[ -f .env ] && eval "$(grep -v '^#' .env | sed 's/^/export /')"
set +a

# Get list of current node IPs
terraform output -json node_ips | jq | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' > current

# Get list of current node names
terraform output -json node_names | jq | tr -d '",[] ' > current_names

# Terraform apply
terraform apply -auto-approve -var $TOKEN

# Get list of new node IPs
terraform output -json node_ips | jq | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' > new

# Get list of new node names
terraform output -json node_names | jq | tr -d '",[] ' > new_names

# Compare for changes between lists
sort current new | uniq -u > unique
sort current_names new_names | uniq -u > unique_names

# Sort new nodes IPs and add them to the cluster
cat unique | while read -r ip;  
do echo ; 
echo "Node IP: ${ip}";
k3sup join --k3s-version $VERSION --ip ${ip} --server-ip $SERVER_IP --user $USER; 
done

# Add labels to the new nodes
cat unique_names | while read -r name;
do
    echo
    max_attempts=5
    attempt=1
    wait_time=15  # seconds

    while [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt of $max_attempts: Checking node ${name}"
        if kubectl get node "${name}" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep -q "True"; then
            echo "Node ${name} is Ready"
            kubectl label node ${name} ${LABEL}
            break
        else
            echo "Node ${name} is not Ready. Waiting ${wait_time} seconds before retrying..."
            sleep $wait_time
            ((attempt++))
        fi
    done

    if [ $attempt -gt $max_attempts ]; then
        echo "Node ${name} did not become Ready after $max_attempts attempts. Skipping label addition."
    fi
done

# Clear up generated files
rm current new unique current_names new_names unique_names
