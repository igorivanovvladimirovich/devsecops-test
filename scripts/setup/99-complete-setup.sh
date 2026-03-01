#!/bin/bash

set -e

echo "========================================="
echo "  DevSecOps Complete Setup"
echo "  Estimated cost: $8-12 for 5 days"
echo "========================================="
echo ""

# Load environment
source .env

# Run all setup scripts in order
SCRIPTS=(
    "00-prerequisites.sh"
    "01-gcp-setup.sh"
    "02-terraform-init.sh"
    "03-deploy-infrastructure.sh"
    "04-deploy-kubernetes.sh"
    "05-deploy-functions.sh"
    "06-deploy-cloud-run.sh"
)

for script in "${SCRIPTS[@]}"; do
    echo ""
    echo "================================================"
    echo "  Running: $script"
    echo "================================================"
    bash "scripts/setup/$script"
    
    if [ $? -ne 0 ]; then
        echo "❌ Error in $script"
        exit 1
    fi
done

echo ""
echo "========================================="
echo "  ✅ SETUP COMPLETE!"
echo "========================================="
echo ""
echo "📊 Dashboard URL:"
gcloud run services describe security-dashboard --region=us-central1 --format='value(status.url)'
echo ""
echo "🎯 Next steps:"
echo "  1. Check vulnerabilities: kubectl get vulnerabilityreports -A"
echo "  2. View BigQuery data:"
echo "     https://console.cloud.google.com/bigquery?project=$PROJECT_ID"
echo "  3. Create exploit PR: bash scripts/exploitation/create-exploit-branch.sh"
echo "  4. Monitor costs: bash scripts/cost-optimization/check-costs.sh"
echo ""
echo "📚 Documentation: docs/SETUP.md"
echo ""
echo "💰 Estimated daily cost: $1.50-2.50"
echo "⚠️  Remember to cleanup when done: bash scripts/cleanup/cleanup-all.sh"