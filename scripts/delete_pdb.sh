#!/bin/bash

# Fetch all PDBs across all namespaces
PDBS=$(kubectl get pdb -A -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}')

if [ -z "$PDBS" ]; then
  echo "No Pod Disruption Budgets found to delete."
  exit 0
fi

echo "Deleting the following Pod Disruption Budgets:"
echo "$PDBS"

# Delete each PDB
while read -r NAMESPACE NAME; do
  echo "Deleting PDB: $NAME in namespace: $NAMESPACE"
  kubectl delete pdb $NAME -n $NAMESPACE
done <<< "$PDBS"

echo "All Pod Disruption Budgets have been deleted."

