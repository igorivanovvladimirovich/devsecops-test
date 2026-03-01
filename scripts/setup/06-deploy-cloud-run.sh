#!/bin/bash

set -e

echo "=== Deploying Cloud Run Security Dashboard ==="

source .env

cd cloud-run

# Build and deploy
bash build-and-deploy.sh

cd ..

echo ""
echo "✅ Cloud Run dashboard deployed"