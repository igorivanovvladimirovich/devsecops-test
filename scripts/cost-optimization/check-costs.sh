#!/bin/bash

echo "=== GCP Cost Analysis ==="

source .env 2>/dev/null || PROJECT_ID=$(gcloud config get-value project)

echo ""
echo "Project: $PROJECT_ID"
echo "Period: Last 7 days"
echo ""

# Current month costs
echo "1. Current Month Costs:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
gcloud billing accounts list --format="table(displayName,open)" 2>/dev/null

BILLING_ACCOUNT=$(gcloud beta billing projects describe $PROJECT_ID --format="value(billingAccountName)" 2>/dev/null)

if [ -n "$BILLING_ACCOUNT" ]; then
    echo ""
    echo "Billing account: $BILLING_ACCOUNT"
    echo ""
    echo "⚠️  Note: Use Cloud Console for detailed cost breakdown:"
    echo "https://console.cloud.google.com/billing/reports?project=$PROJECT_ID"
fi

# Resource inventory
echo ""
echo "2. Current Resources:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "GKE Clusters:"
gcloud container clusters list --format="table(name,location,currentNodeCount,status)"

echo ""
echo "Cloud Functions:"
gcloud functions list --gen2 --format="table(name,state,runtime)"

echo ""
echo "Cloud Run Services:"
gcloud run services list --format="table(name,region,url)"

echo ""
echo "BigQuery Datasets:"
bq ls --format=pretty

echo ""
echo "Cloud Storage Buckets:"
gsutil ls

# Estimate costs
echo ""
echo "3. Estimated Daily Costs:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Get GKE info
GKE_NODES=$(gcloud container clusters describe ${CLUSTER_NAME} --region=${REGION} --format="value(currentNodeCount)" 2>/dev/null || echo "0")
GKE_TYPE=$(gcloud container clusters describe ${CLUSTER_NAME} --region=${REGION} --format="value(autopilot.enabled)" 2>/dev/null)

if [ "$GKE_TYPE" = "True" ]; then
    echo "GKE Autopilot (pay-per-pod):"
    
    # Count pods
    RUNNING_PODS=$(kubectl get pods --all-namespaces --field-selector=status.phase=Running 2>/dev/null | wc -l)
    echo "  Running pods: $RUNNING_PODS"
    echo "  Estimated: ~\$0.40-0.80/day"
else
    echo "GKE Standard:"
    echo "  Nodes: $GKE_NODES"
    echo "  Estimated: ~\$1.50-2.00/day"
fi

echo ""
echo "Cloud Functions (2nd gen):"
CF_COUNT=$(gcloud functions list --gen2 2>/dev/null | grep -c "ACTIVE" || echo "0")
echo "  Active functions: $CF_COUNT"
echo "  Estimated: \$0 (free tier)"

echo ""
echo "Cloud Run:"
CR_COUNT=$(gcloud run services list 2>/dev/null | grep -c "READY" || echo "0")
echo "  Active services: $CR_COUNT"
echo "  Estimated: \$0.10-0.30/day"

echo ""
echo "BigQuery:"
BQ_SIZE=$(bq ls --format=json security_data 2>/dev/null | jq '.[0].numBytes // 0' | numfmt --to=iec 2>/dev/null || echo "0")
echo "  Dataset size: $BQ_SIZE"
echo "  Estimated: \$0 (free tier)"

echo ""
echo "Cloud Storage:"
BUCKET_COUNT=$(gsutil ls 2>/dev/null | wc -l)
echo "  Buckets: $BUCKET_COUNT"
echo "  Estimated: \$0.10-0.20/day"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "TOTAL ESTIMATED: \$1.50-2.50/day"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "4. Cost Optimization Tips:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  💡 Scale down when not testing:"
echo "     bash scripts/cost-optimization/scale-down.sh"
echo ""
echo "  💡 Delete cluster but keep data:"
echo "     bash scripts/cleanup/cleanup-keep-data.sh"
echo ""
echo "  💡 Use Budget alerts:"
echo "     https://console.cloud.google.com/billing/budgets?project=$PROJECT_ID"