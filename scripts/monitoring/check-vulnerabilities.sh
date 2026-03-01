#!/bin/bash

echo "=== Checking Vulnerabilities ==="

source .env 2>/dev/null || true

echo ""
echo "1. Kubernetes Vulnerability Reports:"
echo "======================================"
kubectl get vulnerabilityreports -A

echo ""
echo "2. Summary by Severity:"
echo "======================================"
kubectl get vulnerabilityreports -A -o json | \
    jq -r '.items[] | .report.summary | to_entries[] | "\(.key): \(.value)"' | \
    sort | uniq -c

echo ""
echo "3. Critical Vulnerabilities:"
echo "======================================"
kubectl get vulnerabilityreports -A -o json | \
    jq -r '.items[] | select(.report.summary.criticalCount > 0) | 
    "\(.metadata.namespace)/\(.metadata.name): \(.report.summary.criticalCount) CRITICAL"'

echo ""
echo "4. BigQuery Statistics:"
echo "======================================"
bq query --use_legacy_sql=false "
SELECT 
    severity,
    COUNT(*) as count,
    COUNT(DISTINCT resource_namespace) as affected_namespaces
FROM \`${PROJECT_ID}.security_data.vulnerabilities\`
WHERE scan_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
GROUP BY severity
ORDER BY 
    CASE severity
        WHEN 'CRITICAL' THEN 1
        WHEN 'HIGH' THEN 2
        WHEN 'MEDIUM' THEN 3
        WHEN 'LOW' THEN 4
    END
"

echo ""
echo "5. Top 10 Most Vulnerable Packages:"
echo "======================================"
bq query --use_legacy_sql=false "
SELECT 
    package_name,
    COUNT(*) as vuln_count,
    MAX(cvss_score) as max_cvss
FROM \`${PROJECT_ID}.security_data.vulnerabilities\`
WHERE scan_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
GROUP BY package_name
ORDER BY vuln_count DESC
LIMIT 10
"