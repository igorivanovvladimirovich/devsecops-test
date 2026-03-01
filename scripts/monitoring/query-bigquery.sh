#!/bin/bash

echo "=== BigQuery Security Data Queries ==="

source .env

PROJECT_ID=${PROJECT_ID:-$(gcloud config get-value project)}

echo ""
echo "Select a query:"
echo "1. Recent vulnerabilities"
echo "2. APT indicators"
echo "3. Vulnerability trends"
echo "4. Resource compliance"
echo "5. Custom query"
echo ""

read -p "Enter choice (1-5): " choice

case $choice in
    1)
        echo ""
        echo "Recent Vulnerabilities (last 24h):"
        bq query --use_legacy_sql=false "
        SELECT 
            scan_time,
            resource_namespace,
            resource_name,
            severity,
            vulnerability_id,
            package_name,
            cvss_score
        FROM \`${PROJECT_ID}.security_data.vulnerabilities\`
        WHERE scan_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
        ORDER BY cvss_score DESC, scan_time DESC
        LIMIT 50
        "
        ;;
    2)
        echo ""
        echo "APT Indicators:"
        bq query --use_legacy_sql=false "
        SELECT 
            detection_time,
            indicator_type,
            resource_name,
            namespace,
            risk_score,
            details
        FROM \`${PROJECT_ID}.security_data.apt_indicators\`
        ORDER BY detection_time DESC
        LIMIT 50
        "
        ;;
    3)
        echo ""
        echo "Vulnerability Trends (7 days):"
        bq query --use_legacy_sql=false "
        SELECT 
            DATE(scan_time) as date,
            severity,
            COUNT(*) as count
        FROM \`${PROJECT_ID}.security_data.vulnerabilities\`
        WHERE scan_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
        GROUP BY date, severity
        ORDER BY date DESC, severity
        "
        ;;
    4)
        echo ""
        echo "Resource Compliance Status:"
        bq query --use_legacy_sql=false "
        WITH latest_scans AS (
            SELECT 
                resource_namespace,
                resource_name,
                MAX(scan_time) as last_scan,
                SUM(CASE WHEN severity IN ('CRITICAL', 'HIGH') THEN 1 ELSE 0 END) as high_critical_count
            FROM \`${PROJECT_ID}.security_data.vulnerabilities\`
            WHERE scan_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
            GROUP BY resource_namespace, resource_name
        )
        SELECT 
            resource_namespace,
            resource_name,
            last_scan,
            high_critical_count,
            CASE 
                WHEN high_critical_count = 0 THEN 'COMPLIANT'
                WHEN high_critical_count <= 3 THEN 'WARNING'
                ELSE 'NON_COMPLIANT'
            END as status
        FROM latest_scans
        ORDER BY high_critical_count DESC
        "
        ;;
    5)
        echo ""
        read -p "Enter your SQL query: " custom_query
        bq query --use_legacy_sql=false "$custom_query"
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac