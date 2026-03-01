#!/bin/bash

set -e

echo "=== Deploying Kubernetes Components ==="

source .env

# Get GKE credentials
echo "Getting GKE credentials..."
gcloud container clusters get-credentials ${CLUSTER_NAME} \
    --region ${REGION} \
    --project ${PROJECT_ID}

echo "✅ Connected to GKE cluster"

# Create namespaces
echo ""
echo "Creating namespaces..."
kubectl apply -f k8s/namespaces/

# Deploy Trivy Operator
echo ""
echo "Deploying Trivy Operator..."
helm repo add aqua https://aquasecurity.github.io/helm-charts/
helm repo update

# Update values with project ID
envsubst < k8s/trivy-operator/values.yaml > /tmp/trivy-values.yaml

helm upgrade --install trivy-operator aqua/trivy-operator \
    --namespace trivy-system \
    --create-namespace \
    --values /tmp/trivy-values.yaml \
    --wait

echo "✅ Trivy Operator deployed"

# Setup Workload Identity for Trivy
echo ""
echo "Setting up Workload Identity for Trivy..."

kubectl annotate serviceaccount trivy-operator \
    -n trivy-system \
    iam.gke.io/gcp-service-account=trivy-operator@${PROJECT_ID}.iam.gserviceaccount.com \
    --overwrite

gcloud iam service-accounts add-iam-policy-binding \
    trivy-operator@${PROJECT_ID}.iam.gserviceaccount.com \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:${PROJECT_ID}.svc.id.goog[trivy-system/trivy-operator]"

echo "✅ Workload Identity configured"

# Deploy Trivy Pub/Sub publisher
echo ""
echo "Deploying Trivy log publisher..."
envsubst < k8s/trivy-operator/pubsub-publisher.yaml | kubectl apply -f -

# Deploy Falco
echo ""
echo "Deploying Falco (IDS/IPS)..."
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update

envsubst < k8s/falco/values.yaml > /tmp/falco-values.yaml

helm upgrade --install falco falcosecurity/falco \
    --namespace security-monitoring \
    --create-namespace \
    --values /tmp/falco-values.yaml \
    --wait

echo "✅ Falco deployed"

# Deploy vulnerable applications
echo ""
echo "Deploying vulnerable applications..."
kubectl apply -f k8s/vulnerable-apps/

# Deploy APT simulation pods
echo ""
echo "Deploying APT simulation..."
kubectl apply -f k8s/apt-simulation/

# Deploy network policies
echo ""
echo "Deploying network policies..."
kubectl apply -f k8s/network-policies/

echo ""
echo "✅ All Kubernetes components deployed"
echo ""
echo "Waiting for Trivy to scan workloads (60 seconds)..."
sleep 60

echo ""
echo "Checking vulnerability reports..."
kubectl get vulnerabilityreports -A