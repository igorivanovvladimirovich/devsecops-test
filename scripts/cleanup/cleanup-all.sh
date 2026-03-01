#!/bin/bash

set -e

echo "========================================="
echo "  Complete Cleanup (Delete Everything)"
echo "========================================="
echo ""
echo "⚠️  WARNING: This will delete:"
echo "  • GKE cluster and all workloads"
echo "  • Cloud Functions"
echo "  • Cloud Run services"
echo "  • BigQuery datasets"
echo "  • Cloud Storage buckets"
echo "  • All Terraform-managed infrastructure"
echo ""

read -p "Are you absolutely sure? (type 'yes' to confirm): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled"
    exit 0
fi

source .env 2>/dev/null || PROJECT_ID=$(gcloud config get-value project)

echo ""
echo "Starting cleanup..."

# Delete Kubernetes resources first
echo ""
echo "1. Deleting Kubernetes resources..."
kubectl delete namespace apt-simulation --ignore-not-found=true
kubectl delete namespace vulnerable-apps --ignore-not-found=true
kubectl delete namespace security-monitoring --ignore-not-found=true
helm uninstall trivy-operator -n trivy-system 2>/dev/null || true
helm uninstall falco -n security-monitoring 2>/dev/null || true
kubectl delete namespace trivy-system --ignore-not-found=true

echo "✅ Kubernetes resources deleted"

# Delete Cloud Functions
echo ""
echo "2. Deleting Cloud Functions..."
gcloud functions delete process-trivy-reports --region=us-central1 --gen2 --quiet 2>/dev/null || true
gcloud functions delete detect-apt-indicators --region=us-central1 --gen2 --quiet 2>/dev/null || true

echo "✅ Cloud Functions deleted"

# Delete Cloud Run
echo ""
echo "3. Deleting Cloud Run services..."
gcloud run services delete security-dashboard --region=us-central1 --quiet 2>/dev/null || true

echo "✅ Cloud Run services deleted"

# Terraform destroy
echo ""
echo "4. Destroying Terraform infrastructure..."
cd terraform
terraform destroy -auto-approve
cd ..

echo "✅ Terraform resources destroyed"

# Delete local state
echo ""
echo "5. Cleaning local state..."
rm -rf terraform/.terraform
rm -f terraform/terraform.tfstate*
rm -f terraform/tfplan
rm -f .env
rm -f outputs.json

echo "✅ Local state cleaned"

# Delete kind cluster if exists
echo ""
echo "6. Deleting local kind cluster..."
kind delete cluster --name devsecops-local 2>/dev/null || true
kind delete cluster --name vuln-cluster 2>/dev/null || true

echo "✅ Local clusters deleted"

echo ""
echo "========================================="
echo "  ✅ Cleanup Complete!"
echo "========================================="
echo ""
echo "All resources have been deleted."
echo "Final costs should be $0/hour going forward."
echo ""