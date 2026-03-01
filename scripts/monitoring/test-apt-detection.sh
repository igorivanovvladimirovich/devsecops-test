#!/bin/bash

echo "=== Testing APT Detection ==="

source .env

echo ""
echo "This script will:"
echo "1. Deploy APT simulation pods"
echo "2. Wait for Falco to detect indicators"
echo "3. Check BigQuery for APT alerts"
echo ""

read -p "Continue? (y/n): " confirm

if [ "$confirm" != "y" ]; then
    echo "Cancelled"
    exit 0
fi

# Deploy APT simulation
echo ""
echo "Deploying APT simulation pods..."
kubectl apply -f k8s/apt-simulation/

echo ""
echo "Waiting 30 seconds for detection..."
sleep 30

# Check Falco logs
echo ""
echo "Checking Falco alerts:"
kubectl logs -n security-monitoring -l app.kubernetes.io/name=falco --tail=50 | grep -i "apt alert" || echo "No APT alerts in Falco logs yet"

# Check BigQuery
echo ""
echo "Checking BigQuery for APT indicators:"
bq query --use_legacy_sql=false "
SELECT 
    detection_time,
    indicator_type,
    resource_name,
    risk_score
FROM \`${PROJECT_ID}.security_data.apt_indicators\`
WHERE detection_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 5 MINUTE)
ORDER BY detection_time DESC
"

# Check pod logs
echo ""
echo "Checking crypto-miner pod logs:"
kubectl logs -n apt-simulation fake-crypto-miner --tail=20 || echo "Pod not ready yet"

echo ""
echo "Checking C&C connector logs:"
kubectl logs -n apt-simulation cc-connector --tail=20 || echo "Pod not ready yet"

echo ""
echo "Test complete!"
echo ""
echo "To cleanup APT simulation:"
echo "  kubectl delete namespace apt-simulation"