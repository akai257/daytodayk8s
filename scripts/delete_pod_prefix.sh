#!/bin/bash

# Usage: ./delete_pods.sh <namespace> <prefix>
# Example: ./delete_pods.sh my-namespace my-prefix

NAMESPACE=$1
PREFIX=$2

if [[ -z "$NAMESPACE" || -z "$PREFIX" ]]; then
  echo "Usage: $0 <namespace> <prefix>"
  exit 1
fi

echo "Deleting pods with prefix '$PREFIX' in namespace '$NAMESPACE'..."

# Get all pods in the namespace with the given prefix
PODS=$(kubectl get pods -n "$NAMESPACE" --no-headers | awk "/^$PREFIX/ {print \$1}")

if [[ -z "$PODS" ]]; then
  echo "No pods found with prefix '$PREFIX' in namespace '$NAMESPACE'."
  exit 0
fi

# Delete each pod
for POD in $PODS; do
  echo "Deleting pod: $POD"
  kubectl delete pod "$POD" -n "$NAMESPACE" --grace-period=0 --force
done

echo "Deletion complete."

