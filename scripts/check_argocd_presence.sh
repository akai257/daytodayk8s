#!/bin/bash

KUBECONFIG_DIR="$HOME/.kube"
missing_argocd_clusters=()

echo "🔍 Checking Argo CD installation across uat* and prod* clusters..."

for kubeconfig in "$KUBECONFIG_DIR"/{uat*,prod*}-master-config.yaml; do
  [[ ! -f "$kubeconfig" ]] && continue

  export KUBECONFIG="$kubeconfig"
  cluster_name=$(basename "$kubeconfig" -master-config.yaml)

  echo -n "⛵ $cluster_name: "

  if helm ls -n argocd --kubeconfig "$kubeconfig" 2>/dev/null | grep -q argo-cd; then
    echo "✅ Argo CD is installed"
  else
    echo "❌ Argo CD NOT found"
    missing_argocd_clusters+=("$cluster_name")
  fi
done

echo ""
echo "📋 Clusters WITHOUT Argo CD installed:"
for cluster in "${missing_argocd_clusters[@]}"; do
  echo " - $cluster"
done

