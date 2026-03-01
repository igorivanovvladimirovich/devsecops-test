#!/bin/bash

set -e

echo "=== Deploying Cloud Functions ==="

# source .env

cd functions

# Build function packages
echo "Building function packages..."

# Process Trivy function
cd process_trivy
zip -r ../process-trivy.zip . -x "*.pyc" -x "__pycache__/*"
cd ..

# APT Detection function
cd detect_apt
zip -r ../detect-apt.zip . -x "*.pyc" -x "__pycache__/*"
cd ..
PROJECT_ID=$(gcloud config get-value project)
# Upload to Cloud Storage
SCAN_RESULTS_BUCKET="${PROJECT_ID}-scan-results"

echo ""
echo "Uploading function packages..."
gsutil cp process-trivy.zip gs://${SCAN_RESULTS_BUCKET}/functions/
gsutil cp detect-apt.zip gs://${SCAN_RESULTS_BUCKET}/functions/

# Deploy Process Trivy function
echo ""
echo "Deploying process-trivy-reports function..."

gcloud functions deploy process-trivy-reports \
    --gen2 \
    --runtime python311 \
    --region ${REGION} \
    --source gs://${SCAN_RESULTS_BUCKET}/functions/process-trivy.zip \
    --entry-point process_report \
    --trigger-topic trivy-reports \
    --service-account cloud-functions-sa@${PROJECT_ID}.iam.gserviceaccount.com \
    --set-env-vars PROJECT_ID=${PROJECT_ID},DATASET_ID=security_data \
    --memory 256MB \
    --timeout 60s \
    --max-instances 3 \
    --min-instances 0

echo "✅ process-trivy-reports deployed"

# Deploy APT Detection function
echo ""
echo "Deploying detect-apt-indicators function..."

gcloud functions deploy detect-apt-indicators \
    --gen2 \
    --runtime python311 \
    --region ${REGION} \
    --source gs://${SCAN_RESULTS_BUCKET}/functions/detect-apt.zip \
    --entry-point detect_apt \
    --trigger-topic apt-detection \
    --service-account cloud-functions-sa@${PROJECT_ID}.iam.gserviceaccount.com \
    --set-env-vars PROJECT_ID=${PROJECT_ID},DATASET_ID=security_data,ALERT_TOPIC=security-alerts \
    --memory 256MB \
    --timeout 60s \
    --max-instances 3 \
    --min-instances 0

echo "✅ detect-apt-indicators deployed"

cd ..

echo ""
echo "✅ All Cloud Functions deployed"