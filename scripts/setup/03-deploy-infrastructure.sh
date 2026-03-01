#!/bin/bash

set -e

echo "=== Deploying GCP Infrastructure with Terraform ==="

source .env

cd terraform

# Validate
echo "Validating configuration..."
terraform validate

# Plan
echo ""
echo "Creating execution plan..."
terraform plan -out=tfplan

# Apply
echo ""
read -p "Apply this plan? (yes/no): " confirm

if [ "$confirm" = "yes" ]; then
    echo "Applying infrastructure..."
    terraform apply tfplan
    
    echo ""
    echo "✅ Infrastructure deployed!"
    
    # Save outputs
    terraform output -json > ../outputs.json
    
    # Extract important values
    CLUSTER_NAME=$(terraform output -raw cluster_name)
    REGION=$(terraform output -raw region)
    WIF_PROVIDER=$(terraform output -raw workload_identity_provider)
    GITHUB_SA=$(terraform output -raw github_actions_sa_email)
    
    # Update .env
    cat >> ../.env <<EOF
CLUSTER_NAME=${CLUSTER_NAME}
WIF_PROVIDER=${WIF_PROVIDER}
GITHUB_SA_EMAIL=${GITHUB_SA}
EOF
    
    echo ""
    echo "📝 Important values saved to .env"
    echo ""
    echo "GitHub Secrets to set:"
    echo "  WIF_PROVIDER: ${WIF_PROVIDER}"
    echo "  GCP_SA_EMAIL: ${GITHUB_SA}"
else
    echo "Deployment cancelled"
    exit 1
fi

cd ..