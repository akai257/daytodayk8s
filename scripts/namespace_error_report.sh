#!/bin/bash

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "kubectl could not be found. Please install kubectl."
    exit 1
fi

# Check if namespace is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <namespace>"
    exit 1
fi

NAMESPACE=$1

# Fetch pods in the namespace
PODS=$(kubectl get pods -n "$NAMESPACE" --no-headers)

# Check if any pods exist
if [ -z "$PODS" ]; then
    echo "No pods found in namespace $NAMESPACE."
    exit 0
fi

echo "Analyzing errors for namespace: $NAMESPACE"
echo "---------------------------------------------------------"

# Initialize error counts
TOTAL_PODS=0
ERROR_PODS=0

# Collect errors
declare -A ERROR_TYPES

while IFS= read -r line; do
    TOTAL_PODS=$((TOTAL_PODS + 1))

    # Extract pod name and status
    POD_NAME=$(echo "$line" | awk '{print $1}')
    POD_STATUS=$(echo "$line" | awk '{print $3}')
    
    # Check if pod is in an error state
    if [[ "$POD_STATUS" != "Running" && "$POD_STATUS" != "Completed" ]]; then
        ERROR_PODS=$((ERROR_PODS + 1))

        # Describe pod to get detailed error messages
        ERROR_MESSAGE=$(kubectl describe pod "$POD_NAME" -n "$NAMESPACE" | grep -i "message" | tail -1 | awk -F: '{print $2}' | xargs)
        
        # Use a default message if ERROR_MESSAGE is empty
        if [ -z "$ERROR_MESSAGE" ]; then
            ERROR_MESSAGE="Unknown error or no detailed message available"
        fi

        # Increment error type count
        ERROR_TYPES["$ERROR_MESSAGE"]=$((ERROR_TYPES["$ERROR_MESSAGE"] + 1))
        
        echo "Pod: $POD_NAME | Status: $POD_STATUS | Error: $ERROR_MESSAGE"

        # Fetch last 6 lines of logs
        echo "Last 6 lines of logs for $POD_NAME:"
        kubectl logs "$POD_NAME" -n "$NAMESPACE" --tail=6 2>/dev/null || echo "No logs available"
        echo "---------------------------------------------------------"
    fi
done <<< "$PODS"

# Print summary
echo "---------------------------------------------------------"
echo "Total Pods: $TOTAL_PODS"
echo "Error Pods: $ERROR_PODS"

echo "Error Analysis:"
if [ "${#ERROR_TYPES[@]}" -eq 0 ]; then
    echo "No errors found."
else
    for ERROR in "${!ERROR_TYPES[@]}"; do
        echo "- ${ERROR_TYPES[$ERROR]} occurrences of: $ERROR"
    done
fi

