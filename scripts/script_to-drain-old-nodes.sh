#!/bin/bash

# Define the age threshold for old nodes
AGE_THRESHOLD="8d"

# Fetch nodes that match the age threshold (e.g., 8d old)
OLD_NODES=$(kubectl get nodes | grep -v control | grep " $AGE_THRESHOLD " | awk '{print $1}')

# Fetch new nodes (nodes that do not match the age threshold)
NEW_NODES=$(kubectl get nodes | grep -v control | grep -v " $AGE_THRESHOLD " | awk '{print $1}')

echo "Old Nodes to cordon:"
echo "$OLD_NODES"
echo "New Nodes available:"
echo "$NEW_NODES"

if [ -z "$OLD_NODES" ]; then
  echo "No old nodes found to cordon and drain."
  exit 0
fi

# First stage: Cordon each old node
for NODE in $OLD_NODES; do
  echo "Cordoning node: $NODE"
  kubectl cordon $NODE
  if [ $? -eq 0 ]; then
    echo "Successfully cordoned node: $NODE"
  else
    echo "Failed to cordon node: $NODE"
  fi
done

# Second stage: Drain each old node
for NODE in $OLD_NODES; do
  echo "Draining node: $NODE"
  kubectl drain $NODE --ignore-daemonsets --delete-emptydir-data --force
  if [ $? -eq 0 ]; then
    echo "Successfully drained node: $NODE"
  else
    echo "Failed to drain node: $NODE"
  fi
done

# Verify nodes are cordoned and workloads moved
echo "Cordoned and drained nodes:"
kubectl get nodes | grep -v control | grep " $AGE_THRESHOLD "

# Clean up unnecessary resources (optional)
echo "Cleaning up DaemonSets..."
kubectl get daemonsets --all-namespaces -o name | while read DS; do
  echo "Deleting DaemonSet: $DS"
  kubectl delete $DS
done

# Confirm cleanup
echo "Final state of nodes:"
kubectl get nodes

echo "Script execution completed."

