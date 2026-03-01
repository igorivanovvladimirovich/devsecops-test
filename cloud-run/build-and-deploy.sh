#!/bin/bash

set -e

echo "=== Building and Deploying Security Dashboard to Cloud Run ==="

PROJECT_ID=$(gcloud config get-value project)
REGION="us-central1"
SERVICE_NAME="security-dashboard"
REPO_NAME="devsecops-containers"

cd security-dashboard

# Build container image
echo "Building container image..."
gcloud builds submit --tag ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${SERVICE_NAME}:latest

# Deploy to Cloud Run
echo "Deploying to Cloud Run..."
gcloud run deploy ${SERVICE_NAME} \
  --image ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${SERVICE_NAME}:latest \
  --region ${REGION} \
  --platform managed \
  --allow-unauthenticated \
  --set-env-vars PROJECT_ID=${PROJECT_ID},DATASET_ID=security_data \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 0 \
  --max-instances 2 \
  --timeout 60

# Get URL
SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} --region ${REGION} --format 'value(status.url)')

echo ""
echo "✅ Dashboard deployed!"
echo "📊 URL: ${SERVICE_URL}"