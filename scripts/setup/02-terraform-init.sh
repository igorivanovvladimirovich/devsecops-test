#!/bin/bash

set -e

echo "=== Terraform Initialization ==="

source .env

cd terraform

# Create terraform.tfvars
cat > terraform.tfvars <<EOF
project_id    = "${PROJECT_ID}"
region        = "${REGION}"
zone          = "${ZONE}"
cluster_name  = "${CLUSTER_NAME}"
github_owner  = "$(git config user.name || echo 'YOUR_GITHUB_USERNAME')"
github_repo   = "$(basename $(git rev-parse --show-toplevel) 2>/dev/null || echo 'devsecops-test')"
alert_email   = "$(gcloud config get-value account)"
EOF

echo "✅ terraform.tfvars created"

# Create backend bucket
TF_STATE_BUCKET="${PROJECT_ID}-tfstate"

if ! gsutil ls -b gs://${TF_STATE_BUCKET} &>/dev/null; then
    echo "Creating state bucket..."
    gsutil mb -p ${PROJECT_ID} -l ${REGION} gs://${TF_STATE_BUCKET}
    gsutil versioning set on gs://${TF_STATE_BUCKET}
    echo "✅ State bucket created"
else
    echo "✅ State bucket exists"
fi

# Create backend.tf
cat > backend.tf <<EOF
terraform {
  backend "gcs" {
    bucket = "${TF_STATE_BUCKET}"
    prefix = "terraform/state"
  }
}
EOF

echo "✅ backend.tf configured"

# Initialize
echo ""
echo "Initializing Terraform..."
terraform init

echo ""
echo "✅ Terraform initialized"

cd ..