#!/bin/bash

echo "🔍 Checking which ingress HOSTS resolve..."

# Initialize an array to store resolving hosts
resolving_hosts=()

# Use process substitution to avoid subshell
while read -r host; do
  if [[ -n "$host" ]]; then
    if nslookup "$host" >/dev/null 2>&1; then
      resolving_hosts+=("$host")
    fi
  fi
done < <(kubectl get ingress -A | awk 'NR>1 {print $4}' | sort -u)

# Print all resolving hosts at the end
echo "✅ The following ingress HOSTS resolve successfully:"
printf '%s\n' "${resolving_hosts[@]}"

