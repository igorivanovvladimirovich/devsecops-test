#!/bin/bash

echo "=== Cleanup (Keep BigQuery Data) ==="

source .env 2>/dev/null || true

echo ""
echo "This will delete:"
echo "  ✅ GKE cluster (saves ~$1.50/day)"
echo "  ✅ Cloud Functions"
echo "  ✅ Cloud Run services"
echo "  ❌ Keep BigQuery data for analysis"
echo "  ❌ Keep Cloud Storage buckets"
echo ""

read -p "Continue? (y/n): " confirm

if [ "$confirm" != "y" ]; then
    exit 0
fi

# Delete GKE cluster
echo ""
echo "Deleting GKE cluster..."
gcloud container clusters delete ${CLUSTER_NAME} --region ${REGION} --quiet

# Delete Cloud Functions
echo ""
echo "Deleting Cloud Functions..."
gcloud functions delete process-trivy-reports --region=${REGION} --gen2 --quiet 2>/dev/null || true
gcloud functions delete detect-apt-indicators --region=${REGION} --gen2 --quiet 2>/dev/null || true

# Delete Cloud Run
echo ""
echo "Deleting Cloud Run..."
gcloud run services delete security-dashboard --region=${REGION} --quiet 2>/dev/null || true

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "Data preserved in:"
echo "  • BigQuery: ${PROJECT_ID}.security_data"
echo "  • Cloud Storage: gs://${PROJECT_ID}-*"
echo ""
echo "To query data:"
echo "  bash scripts/monitoring/query-bigquery.sh"