#!/bin/bash

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "kubectl could not be found. Please install kubectl."
    exit 1
fi

# Get the worker nodes (nodes that are not control-plane)
WORKER_NODES=$(kubectl get nodes --no-headers | grep -v control-plane | awk '{print $1}')

# Check if worker nodes are found
if [ -z "$WORKER_NODES" ]; then
    echo "No worker nodes found in the cluster."
    exit 1
fi

# Display header for the table
printf "%-45s %-15s %-15s %-15s\n" "Node Name" "Total Pods" "Running Pods" "Error Pods (CrashLoopBackOff, etc.)"
printf "%-45s %-15s %-15s %-15s\n" "---------------------------------------------" "---------------" "---------------" "---------------"

# Initialize totals
TOTAL_ALL_NODES=0
RUNNING_ALL_NODES=0
ERROR_ALL_NODES=0

# Loop through each worker node and count the number of pods in different states
for NODE in $WORKER_NODES; do
    # Fetch pods for the node
    NODE_PODS=$(kubectl get pods --all-namespaces --field-selector spec.nodeName=$NODE --no-headers)

    # Total pods
    TOTAL_PODS=$(echo "$NODE_PODS" | wc -l)
    TOTAL_ALL_NODES=$((TOTAL_ALL_NODES + TOTAL_PODS))

    # Running pods
    RUNNING_PODS=$(echo "$NODE_PODS" | awk '$4 == "Running"' | wc -l)
    RUNNING_ALL_NODES=$((RUNNING_ALL_NODES + RUNNING_PODS))

    # Pods in error states (not Running or Completed)
    ERROR_PODS=$(echo "$NODE_PODS" | awk '$4 != "Running" && $4 != "Completed"' | wc -l)
    ERROR_ALL_NODES=$((ERROR_ALL_NODES + ERROR_PODS))

    # Print the result with proper formatting
    printf "%-45s %-15s %-15s %-15s\n" "$NODE" "$TOTAL_PODS" "$RUNNING_PODS" "$ERROR_PODS"
done

# Print totals at the bottom
printf "%-45s %-15s %-15s %-15s\n" "TOTAL" "$TOTAL_ALL_NODES" "$RUNNING_ALL_NODES" "$ERROR_ALL_NODES"

