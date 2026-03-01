#!/bin/bash

set -e

echo "=== GCP Project Setup ==="

# Variables
export PROJECT_ID=$(gcloud config get-value project)

if [ -z "$PROJECT_ID" ]; then
    echo "❌ No project selected. Run: gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi

echo "Using project: $PROJECT_ID"

# Check billing
BILLING_ENABLED=$(gcloud beta billing projects describe $PROJECT_ID --format="value(billingEnabled)" 2>/dev/null || echo "false")

if [ "$BILLING_ENABLED" != "True" ]; then
    echo "⚠️  Billing not enabled. Enable at:"
    echo "https://console.cloud.google.com/billing/linkedaccount?project=$PROJECT_ID"
    exit 1
fi

echo "✅ Billing enabled"

# Enable APIs
echo ""
echo "Enabling required APIs..."

APIS=(
    "container.googleapis.com"
    "compute.googleapis.com"
    "cloudbuild.googleapis.com"
    "cloudfunctions.googleapis.com"
    "run.googleapis.com"
    "bigquery.googleapis.com"
    "pubsub.googleapis.com"
    "artifactregistry.googleapis.com"
    "secretmanager.googleapis.com"
    "iam.googleapis.com"
    "cloudresourcemanager.googleapis.com"
    "logging.googleapis.com"
    "monitoring.googleapis.com"
    "binaryauthorization.googleapis.com"
)

for api in "${APIS[@]}"; do
    echo "  Enabling $api..."
    gcloud services enable $api --project=$PROJECT_ID
done

echo ""
echo "✅ All APIs enabled"

# Save config
cat > .env <<EOF
PROJECT_ID=$PROJECT_ID
REGION=us-central1
ZONE=us-central1-a
CLUSTER_NAME=devsecops-gke
EOF

echo "✅ Configuration saved to .env"