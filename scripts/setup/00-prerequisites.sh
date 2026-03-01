#!/bin/bash

echo "=== Checking Prerequisites ==="

# Check gcloud
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI not found. Install from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi
echo "✅ gcloud CLI installed"

# Check terraform
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform not found. Install from: https://www.terraform.io/downloads"
    exit 1
fi
echo "✅ Terraform installed"

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Installing..."
    gcloud components install kubectl
fi
echo "✅ kubectl installed"

# Check helm
if ! command -v helm &> /dev/null; then
    echo "❌ Helm not found. Installing..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi
echo "✅ Helm installed"

# Check kind (for local cluster)
if ! command -v kind &> /dev/null; then
    echo "❌ Kind not found. Installing..."
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
fi
echo "✅ Kind installed"

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 not found"
    exit 1
fi
echo "✅ Python 3 installed"

echo ""
echo "✅ All prerequisites met!"