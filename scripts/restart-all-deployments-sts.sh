#!/bin/bash

# Set namespace to empty for all (except kube-system)
EXCLUDED_NAMESPACE="kube-system"

echo "🚀 Restarting all Deployments and StatefulSets in Kubernetes (excluding $EXCLUDED_NAMESPACE)..."

# Restart all Deployments except in kube-system
echo "🔄 Restarting Deployments in all namespaces except $EXCLUDED_NAMESPACE..."
kubectl get deployments --all-namespaces -o custom-columns="NAMESPACE:.metadata.namespace,NAME:.metadata.name" | while read -r ns dep; do
    [[ -z "$ns" || -z "$dep" || "$ns" == "NAMESPACE" || "$ns" == "$EXCLUDED_NAMESPACE" ]] && continue
    echo "🔁 Restarting Deployment: $dep in Namespace: $ns"
    kubectl rollout restart deployment "$dep" -n "$ns"
done

# Restart all StatefulSets except in kube-system
echo "🔄 Restarting StatefulSets in all namespaces except $EXCLUDED_NAMESPACE..."
kubectl get statefulsets --all-namespaces -o custom-columns="NAMESPACE:.metadata.namespace,NAME:.metadata.name" | while read -r ns sts; do
    [[ -z "$ns" || -z "$sts" || "$ns" == "NAMESPACE" || "$ns" == "$EXCLUDED_NAMESPACE" ]] && continue
    echo "🔁 Restarting StatefulSet: $sts in Namespace: $ns"
    kubectl rollout restart statefulset "$sts" -n "$ns"
done

echo "✅ All Deployments and StatefulSets (except in $EXCLUDED_NAMESPACE) have been restarted!"

