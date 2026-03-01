#!/bin/bash

echo "=== Scaling Down Resources ==="

source .env 2>/dev/null || true

echo ""
echo "This will:"
echo "  • Scale down deployments to 0 replicas"
echo "  • Stop APT simulation pods"
echo "  • Keep cluster running (minimal cost)"
echo ""

read -p "Continue? (y/n): " confirm

if [ "$confirm" != "y" ]; then
    exit 0
fi

# Scale down deployments
echo ""
echo "Scaling down deployments..."

kubectl scale deployment --all --replicas=0 -n trivy-system
kubectl scale deployment --all --replicas=0 -n security-monitoring
kubectl scale deployment --all --replicas=0 -n vulnerable-apps

# Delete APT simulation
echo ""
echo "Deleting APT simulation pods..."
kubectl delete namespace apt-simulation --ignore-not-found=true

# Scale Cloud Run to 0
echo ""
echo "Scaling Cloud Run to 0..."
gcloud run services update security-dashboard \
    --region=${REGION} \
    --min-instances=0 \
    --max-instances=1

echo ""
echo "✅ Resources scaled down"
echo ""
echo "Current resource usage:"
kubectl top nodes 2>/dev/null || echo "Metrics not available"

echo ""
echo "To scale back up:"
echo "  bash scripts/setup/04-deploy-kubernetes.sh"