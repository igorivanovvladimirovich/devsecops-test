#!/bin/bash

set -e

echo "=== Setting up LOCAL Vulnerable Kubernetes Cluster ==="
echo ""
echo "Purpose: Test vulnerabilities WITHOUT GCP costs"
echo ""

# Create cluster
echo "Creating Kind cluster..."
kind create cluster --config kind-config-vulnerable.yaml

# Wait for cluster
echo "Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=120s

# Deploy vulnerable workloads
echo ""
echo "Deploying vulnerable workloads..."

kubectl create namespace vulnerable-apps

# Privileged container (container escape vulnerability)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: privileged-pod
  namespace: vulnerable-apps
spec:
  hostPID: true
  hostNetwork: true
  containers:
  - name: shell
    image: ubuntu:latest
    command: ["sleep", "infinity"]
    securityContext:
      privileged: true
    volumeMounts:
    - name: host-root
      mountPath: /host
  volumes:
  - name: host-root
    hostPath:
      path: /
EOF

# Pod with capabilities
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: caps-pod
  namespace: vulnerable-apps
spec:
  containers:
  - name: shell
    image: ubuntu:latest
    command: ["sleep", "infinity"]
    securityContext:
      capabilities:
        add:
        - SYS_ADMIN
        - NET_ADMIN
EOF

# Install Trivy Operator
echo ""
echo "Installing Trivy Operator..."
helm repo add aqua https://aquasecurity.github.io/helm-charts/
helm repo update

helm install trivy-operator aqua/trivy-operator \
  --namespace trivy-system \
  --create-namespace \
  --set="trivy.ignoreUnfixed=false"

echo ""
echo "✅ Local cluster ready!"
echo ""
echo "Cluster info:"
kubectl cluster-info

echo ""
echo "Test commands:"
echo "  kubectl get vulnerabilityreports -A"
echo "  kubectl get pods -n vulnerable-apps"
echo "  bash local-k8s/demonstrate-escape.sh"