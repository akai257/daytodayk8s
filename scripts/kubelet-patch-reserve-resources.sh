kubectl patch configmap kubelet-config -n kube-system \
  --type merge \
  --patch "$(cat <<EOF
data:
  kubelet: |
$(kubectl get cm kubelet-config -n kube-system -o jsonpath='{.data.kubelet}' | \
    sed '/^ *kubeReserved:/d;/^ *systemReserved:/d;/^ *evictionHard:/d' | \
    awk '{print "    " $0}')
    kubeReserved:
      cpu: "400m"
      memory: "3Gi"
    systemReserved:
      memory: "1Gi"
    evictionHard:
      memory.available: "500Mi"
EOF
)"

