#!/bin/bash

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "kubectl could not be found. Please install kubectl."
    exit 1
fi

# Get the worker nodes (excluding control-plane)
WORKER_NODES=$(kubectl get nodes --no-headers | grep -v control-plane | awk '{print $1}')
NODE_COUNT=$(echo "$WORKER_NODES" | wc -l)

if [ "$NODE_COUNT" -eq 0 ]; then
    echo "No worker nodes found in the cluster."
    exit 1
fi

# Count total non-CronJob, non-Completed, non-calico pods
TOTAL_POD_COUNT=$(kubectl get pods --all-namespaces --no-headers \
    | grep -v "Completed" \
    | grep -v "calico" \
    | while read -r namespace pod _; do
        # Skip CronJob pods
        if kubectl get pod "$pod" -n "$namespace" -o jsonpath='{.metadata.ownerReferences[0].kind}' 2>/dev/null | grep -q 'Job'; then
            continue
        fi
        echo "$pod"
    done | wc -l)

POD_THRESHOLD=$((TOTAL_POD_COUNT / NODE_COUNT))
echo "Calculated dynamic POD_THRESHOLD: $POD_THRESHOLD"

echo -e "\nNode\t\tPod Count (Filtered)"
echo "-----------------------------------------"

for NODE in $WORKER_NODES; do
    POD_COUNT=$(kubectl get pods --all-namespaces --field-selector spec.nodeName=$NODE --no-headers \
        | grep -v "Completed" \
        | grep -v "calico" \
        | while read -r namespace pod _; do
            if kubectl get pod "$pod" -n "$namespace" -o jsonpath='{.metadata.ownerReferences[0].kind}' 2>/dev/null | grep -q 'Job'; then
                continue
            fi
            echo "$pod"
        done | wc -l)

    echo -e "$NODE\t$POD_COUNT"

    if [ "$POD_COUNT" -gt "$POD_THRESHOLD" ]; then
        echo "Cordoning node: $NODE"
        kubectl cordon "$NODE"

        PODS_TO_DELETE=$((POD_COUNT - POD_THRESHOLD))
        echo "Deleting $PODS_TO_DELETE pods..."

        kubectl get pods --all-namespaces --field-selector spec.nodeName=$NODE --no-headers \
            | grep -v "Completed" \
            | grep -v "calico" \
            | while read -r namespace pod _; do
                if kubectl get pod "$pod" -n "$namespace" -o jsonpath='{.metadata.ownerReferences[0].kind}' 2>/dev/null | grep -q 'Job'; then
                    continue
                fi
                echo "$namespace $pod"
            done | head -n "$PODS_TO_DELETE" \
            | while read -r namespace pod; do
                echo "Deleting pod $pod in $namespace"
                kubectl delete pod "$pod" -n "$namespace" --force --grace-period=0
            done

        kubectl uncordon "$NODE"
    fi
done

echo -e "\n✅ Done: Pods rebalanced across nodes."

