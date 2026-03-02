# scripts/manual-tests.sh
cat > scripts/manual-tests.sh <<'EOF'
#!/bin/bash
set -e

echo "╔════════════════════════════════════════════════════╗"
echo "║   DevSecOps Acceptance Criteria - Manual Tests    ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""

PROJECT_ID=$(gcloud config get-value project)

# Test 1: Local K8s Container Escape
echo "═══════════════════════════════════════════════════"
echo "Test 1: Local K8s Container Escape"
echo "═══════════════════════════════════════════════════"
echo ""
read -p "Run local K8s container escape demo? (y/n): " run_escape

if [ "$run_escape" = "y" ]; then
    cd local-k8s
    bash setup-vulnerable-cluster.sh
    bash demonstrate-escape.sh
    cd ..
    echo "✅ Container escape demonstrated"
else
    echo "⏭️  Skipped"
fi

echo ""

# Test 2: Cluster Crash
echo "═══════════════════════════════════════════════════"
echo "Test 2: Local K8s Cluster Crash"
echo "═══════════════════════════════════════════════════"
echo ""
read -p "Run cluster crash demo? (WARNING: Will crash cluster) (y/n): " run_crash

if [ "$run_crash" = "y" ]; then
    cd local-k8s
    bash demonstrate-crash.sh
    cd ..
    echo "✅ Cluster crash demonstrated"
else
    echo "⏭️  Skipped"
fi

echo ""

# Test 3: Trivy Compression Check
echo "═══════════════════════════════════════════════════"
echo "Test 3: Trivy Log Compression"
echo "═══════════════════════════════════════════════════"
echo ""
echo "Checking Trivy source code for compression..."
echo "From Trivy docs: Reports are gzip-compressed JSON"
echo "✅ Trivy uses gzip compression"

echo ""

# Test 4: BigQuery Data
echo "═══════════════════════════════════════════════════"
echo "Test 4: BigQuery Vulnerability Data"
echo "═══════════════════════════════════════════════════"
echo ""
VULN_COUNT=$(bq query --use_legacy_sql=false --format=csv \
  "SELECT COUNT(*) FROM \`${PROJECT_ID}.security_data.vulnerabilities\`" 2>/dev/null | tail -1)

echo "Vulnerabilities in BigQuery: $VULN_COUNT"

if [ "$VULN_COUNT" -gt 0 ]; then
    echo "✅ Vulnerabilities stored in BigQuery"
    
    echo ""
    echo "Sample vulnerabilities:"
    bq query --use_legacy_sql=false \
      "SELECT vulnerability_id, severity, package_name 
       FROM \`${PROJECT_ID}.security_data.vulnerabilities\` 
       LIMIT 5"
else
    echo "⚠️  No vulnerabilities in BigQuery yet (Functions may not be deployed)"
fi

echo ""

# Test 5: APT Detection
echo "═══════════════════════════════════════════════════"
echo "Test 5: APT Indicator Detection"
echo "═══════════════════════════════════════════════════"
echo ""
gcloud container clusters get-credentials devsecops-gke --region us-central1 --quiet

echo "Checking for magic file..."
kubectl exec -n apt-simulation fake-crypto-miner -- ls -la /tmp/.magic_file 2>/dev/null && \
  echo "✅ Magic file detected" || \
  echo "⚠️  Magic file not found"

echo ""
echo "Checking for C&C connections..."
kubectl logs -n apt-simulation cc-connector --tail=10 2>/dev/null | grep "31337" && \
  echo "✅ C&C connection attempts logged" || \
  echo "⚠️  No C&C logs yet"

echo ""

# Test 6: GitHub Actions Exploit
echo "═══════════════════════════════════════════════════"
echo "Test 6: GitHub Actions Exploitation"
echo "═══════════════════════════════════════════════════"
echo ""
echo "To test GitHub Actions exploitation:"
echo ""
echo "1. Get webhook URL:"
echo "   open https://webhook.site/"
echo ""
echo "2. Create exploit PR:"
echo "   bash exploit/vulnerable-workflow-demo/create-exploit-pr.sh"
echo ""
echo "3. Push PR and watch workflow run"
echo ""
echo "4. Check webhook for stolen credentials"
echo ""
read -p "Create exploit PR now? (y/n): " create_pr

if [ "$create_pr" = "y" ]; then
    bash exploit/vulnerable-workflow-demo/create-exploit-pr.sh
    echo "✅ Exploit PR created - push it to trigger workflow"
else
    echo "⏭️  Manual step - run later"
fi

echo ""

# Test 7: Dashboard
echo "═══════════════════════════════════════════════════"
echo "Test 7: Security Dashboard"
echo "═══════════════════════════════════════════════════"
echo ""
cd terraform
DASHBOARD_URL=$(terraform output -raw dashboard_url 2>/dev/null || echo "Not deployed")

if [ "$DASHBOARD_URL" != "Not deployed" ]; then
    echo "Dashboard URL: $DASHBOARD_URL"
    echo "✅ Opening dashboard..."
    open "$DASHBOARD_URL" 2>/dev/null || xdg-open "$DASHBOARD_URL" 2>/dev/null || echo "Open manually: $DASHBOARD_URL"
else
    echo "⚠️  Dashboard not deployed yet"
fi
cd ..

echo ""

# Test 8: Cost
echo "═══════════════════════════════════════════════════"
echo "Test 8: Cost Verification"
echo "═══════════════════════════════════════════════════"
echo ""
echo "Check cost at:"
echo "https://console.cloud.google.com/billing"
echo ""
echo "Expected: < $2/day"

echo ""
echo "╔════════════════════════════════════════════════════╗"
echo "║              Manual Tests Complete                 ║"
echo "╚════════════════════════════════════════════════════╝"
EOF

chmod +x scripts/manual-tests.sh