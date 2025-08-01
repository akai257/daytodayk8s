#!/bin/bash

set -euo pipefail

NAMESPACE="util"

echo "🔁 Starting safe rolling restarts in namespace: $NAMESPACE"
echo "This will restart DaemonSets, StatefulSets, and Deployments one by one."

# Wait for resource to complete rollout
wait_for_rollout() {
  local kind=$1
  local name=$2

  echo "⏳ Waiting for rollout to complete: $kind/$name..."

  if [[ "$kind" == "daemonset" ]]; then
    kubectl rollout status ds "$name" -n "$NAMESPACE" --timeout=5m
  elif [[ "$kind" == "deployment" ]]; then
    kubectl rollout status deployment "$name" -n "$NAMESPACE" --timeout=5m
  elif [[ "$kind" == "statefulset" ]]; then
    local desired ready
    while true; do
      desired=$(kubectl get sts "$name" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')
      ready=$(kubectl get sts "$name" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
      ready=${ready:-0}  # default to 0 if null
      echo "➡️  $name: Ready $ready / Desired $desired"
      [[ "$ready" == "$desired" ]] && break
      sleep 5
    done
  fi
}

# 🚀 Restart DaemonSets
echo -e "\n🚀 Restarting DaemonSets..."
kubectl get ds -n "$NAMESPACE" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | while read -r ds; do
  echo "🔄 Restarting DaemonSet: $ds"
  kubectl rollout restart ds "$ds" -n "$NAMESPACE"
  wait_for_rollout daemonset "$ds"
done

# 🚀 Restart StatefulSets
echo -e "\n🚀 Restarting StatefulSets..."
kubectl get sts -n "$NAMESPACE" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | while read -r sts; do
  echo "🔄 Restarting StatefulSet: $sts"
  kubectl patch sts "$sts" -n "$NAMESPACE" -p \
    "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"kubectl.kubernetes.io/restartedAt\":\"$(date -Iseconds)\"}}}}}"
  wait_for_rollout statefulset "$sts"
done

# 🚀 Restart Deployments
echo -e "\n🚀 Restarting Deployments..."
kubectl get deployments -n "$NAMESPACE" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' | while read -r deploy; do
  echo "🔄 Restarting Deployment: $deploy"
  kubectl rollout restart deployment "$deploy" -n "$NAMESPACE"
  wait_for_rollout deployment "$deploy"
done

echo -e "\n✅ All restarts completed safely for namespace: $NAMESPACE"

