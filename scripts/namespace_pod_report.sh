#!/bin/bash

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "kubectl could not be found. Please install kubectl."
    exit 1
fi

# Get the namespaces, excluding specified namespaces
EXCLUDED_NAMESPACES="kube-system kube-public argocd default kube-node-lease"
NAMESPACES=$(kubectl get namespaces --no-headers | awk '{print $1}' | grep -v -E "$(echo $EXCLUDED_NAMESPACES | sed 's/ /|/g')")

# Check if namespaces are found
if [ -z "$NAMESPACES" ]; then
    echo "No namespaces found in the cluster after exclusions."
    exit 1
fi

# Display header for the table
printf "%-30s %-15s %-15s %-15s\n" "Namespace" "Total Pods" "Running Pods" "Error Pods (CrashLoopBackOff, etc.)"
printf "%-30s %-15s %-15s %-15s\n" "------------------------------" "---------------" "---------------" "---------------"

# Initialize totals
TOTAL_ALL_NAMESPACES=0
RUNNING_ALL_NAMESPACES=0
ERROR_ALL_NAMESPACES=0

# Loop through each namespace and count the number of pods in different states
for NS in $NAMESPACES; do
    # Fetch pods for the namespace
    NS_PODS=$(kubectl get pods -n "$NS" --no-headers 2>/dev/null)

    # Skip namespaces with no pods
    if [ -z "$NS_PODS" ]; then
        TOTAL_PODS=0
        RUNNING_PODS=0
        ERROR_PODS=0
    else
        # Total pods
        TOTAL_PODS=$(echo "$NS_PODS" | wc -l)
        TOTAL_ALL_NAMESPACES=$((TOTAL_ALL_NAMESPACES + TOTAL_PODS))

        # Running pods
        RUNNING_PODS=$(echo "$NS_PODS" | awk '$3 == "Running"' | wc -l)
        RUNNING_ALL_NAMESPACES=$((RUNNING_ALL_NAMESPACES + RUNNING_PODS))

        # Pods in error states (not Running or Completed)
        ERROR_PODS=$(echo "$NS_PODS" | awk '$3 != "Running" && $3 != "Completed"' | wc -l)
        ERROR_ALL_NAMESPACES=$((ERROR_ALL_NAMESPACES + ERROR_PODS))
    fi

    # Print the result with proper formatting
    printf "%-30s %-15s %-15s %-15s\n" "$NS" "$TOTAL_PODS" "$RUNNING_PODS" "$ERROR_PODS"
done

# Print totals at the bottom
printf "%-30s %-15s %-15s %-15s\n" "TOTAL" "$TOTAL_ALL_NAMESPACES" "$RUNNING_ALL_NAMESPACES" "$ERROR_ALL_NAMESPACES"

