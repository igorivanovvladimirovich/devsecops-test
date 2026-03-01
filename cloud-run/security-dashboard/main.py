#!/usr/bin/env python3
"""
Security Dashboard - Cloud Run Application
Real-time visualization of vulnerabilities and APT indicators
"""

from flask import Flask, render_template, jsonify, request
from google.cloud import bigquery
import os
from datetime import datetime, timedelta

app = Flask(__name__)

PROJECT_ID = os.getenv('PROJECT_ID')
DATASET_ID = os.getenv('DATASET_ID', 'security_data')

# BigQuery client
bq_client = bigquery.Client(project=PROJECT_ID)

@app.route('/')
def index():
    """Main dashboard page"""
    return render_template('index.html', project_id=PROJECT_ID)

@app.route('/api/vulnerabilities/summary')
def vulnerabilities_summary():
    """Get vulnerability summary statistics"""
    query = f"""
    SELECT 
        severity,
        COUNT(*) as count,
        COUNT(DISTINCT resource_namespace) as affected_namespaces,
        COUNT(DISTINCT resource_name) as affected_resources
    FROM `{PROJECT_ID}.{DATASET_ID}.vulnerabilities`
    WHERE scan_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
    GROUP BY severity
    ORDER BY 
        CASE severity
            WHEN 'CRITICAL' THEN 1
            WHEN 'HIGH' THEN 2
            WHEN 'MEDIUM' THEN 3
            WHEN 'LOW' THEN 4
        END
    """
    
    results = bq_client.query(query).result()
    
    summary = []
    for row in results:
        summary.append({
            'severity': row.severity,
            'count': row.count,
            'affected_namespaces': row.affected_namespaces,
            'affected_resources': row.affected_resources
        })
    
    return jsonify(summary)

@app.route('/api/vulnerabilities/recent')
def vulnerabilities_recent():
    """Get recent vulnerabilities"""
    limit = request.args.get('limit', 50, type=int)
    
    query = f"""
    SELECT 
        scan_time,
        resource_namespace,
        resource_name,
        vulnerability_id,
        severity,
        title,
        package_name,
        installed_version,
        fixed_version,
        cvss_score
    FROM `{PROJECT_ID}.{DATASET_ID}.vulnerabilities`
    WHERE scan_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
    ORDER BY scan_time DESC, cvss_score DESC
    LIMIT {limit}
    """
    
    results = bq_client.query(query).result()
    
    vulnerabilities = []
    for row in results:
        vulnerabilities.append({
            'scan_time': row.scan_time.isoformat(),
            'resource_namespace': row.resource_namespace,
            'resource_name': row.resource_name,
            'vulnerability_id': row.vulnerability_id,
            'severity': row.severity,
            'title': row.title,
            'package_name': row.package_name,
            'installed_version': row.installed_version,
            'fixed_version': row.fixed_version,
            'cvss_score': float(row.cvss_score) if row.cvss_score else 0.0
        })
    
    return jsonify(vulnerabilities)

@app.route('/api/vulnerabilities/top-packages')
def top_vulnerable_packages():
    """Get most vulnerable packages"""
    query = f"""
    SELECT 
        package_name,
        COUNT(*) as vulnerability_count,
        MAX(cvss_score) as max_cvss,
        ARRAY_AGG(DISTINCT severity IGNORE NULLS) as severities
    FROM `{PROJECT_ID}.{DATASET_ID}.vulnerabilities`
    WHERE scan_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
    GROUP BY package_name
    ORDER BY vulnerability_count DESC
    LIMIT 10
    """
    
    results = bq_client.query(query).result()
    
    packages = []
    for row in results:
        packages.append({
            'package_name': row.package_name,
            'vulnerability_count': row.vulnerability_count,
            'max_cvss': float(row.max_cvss) if row.max_cvss else 0.0,
            'severities': row.severities
        })
    
    return jsonify(packages)

@app.route('/api/apt/indicators')
def apt_indicators():
    """Get APT detection indicators"""
    query = f"""
    SELECT 
        detection_time,
        indicator_type,
        resource_name,
        namespace,
        details,
        risk_score
    FROM `{PROJECT_ID}.{DATASET_ID}.apt_indicators`
    WHERE detection_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
    ORDER BY detection_time DESC
    LIMIT 100
    """
    
    results = bq_client.query(query).result()
    
    indicators = []
    for row in results:
        indicators.append({
            'detection_time': row.detection_time.isoformat(),
            'indicator_type': row.indicator_type,
            'resource_name': row.resource_name,
            'namespace': row.namespace,
            'details': row.details,
            'risk_score': row.risk_score
        })
    
    return jsonify(indicators)

@app.route('/api/apt/summary')
def apt_summary():
    """Get APT detection summary"""
    query = f"""
    SELECT 
        indicator_type,
        COUNT(*) as count,
        AVG(risk_score) as avg_risk_score,
        MAX(detection_time) as last_detection
    FROM `{PROJECT_ID}.{DATASET_ID}.apt_indicators`
    WHERE detection_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
    GROUP BY indicator_type
    ORDER BY count DESC
    """
    
    results = bq_client.query(query).result()
    
    summary = []
    for row in results:
        summary.append({
            'indicator_type': row.indicator_type,
            'count': row.count,
            'avg_risk_score': float(row.avg_risk_score) if row.avg_risk_score else 0,
            'last_detection': row.last_detection.isoformat() if row.last_detection else None
        })
    
    return jsonify(summary)

@app.route('/api/resources/compliance')
def resources_compliance():
    """Get resource compliance status"""
    query = f"""
    WITH latest_scans AS (
        SELECT 
            resource_namespace,
            resource_name,
            MAX(scan_time) as last_scan_time,
            COUNT(CASE WHEN severity IN ('CRITICAL', 'HIGH') THEN 1 END) as high_severity_count
        FROM `{PROJECT_ID}.{DATASET_ID}.vulnerabilities`
        WHERE scan_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
        GROUP BY resource_namespace, resource_name
    )
    SELECT 
        resource_namespace,
        resource_name,
        last_scan_time,
        high_severity_count,
        CASE 
            WHEN high_severity_count = 0 THEN 'COMPLIANT'
            WHEN high_severity_count <= 3 THEN 'WARNING'
            ELSE 'NON_COMPLIANT'
        END as compliance_status
    FROM latest_scans
    ORDER BY high_severity_count DESC, resource_namespace, resource_name
    """
    
    results = bq_client.query(query).result()
    
    resources = []
    for row in results:
        resources.append({
            'namespace': row.resource_namespace,
            'name': row.resource_name,
            'last_scan': row.last_scan_time.isoformat(),
            'high_severity_count': row.high_severity_count,
            'compliance_status': row.compliance_status
        })
    
    return jsonify(resources)

@app.route('/api/trends/daily')
def daily_trends():
    """Get daily vulnerability trends"""
    query = f"""
    SELECT 
        DATE(scan_time) as scan_date,
        severity,
        COUNT(*) as count
    FROM `{PROJECT_ID}.{DATASET_ID}.vulnerabilities`
    WHERE scan_time > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
    GROUP BY scan_date, severity
    ORDER BY scan_date DESC, severity
    """
    
    results = bq_client.query(query).result()
    
    trends = []
    for row in results:
        trends.append({
            'date': row.scan_date.isoformat(),
            'severity': row.severity,
            'count': row.count
        })
    
    return jsonify(trends)

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'timestamp': datetime.utcnow().isoformat()})

if __name__ == '__main__':
    port = int(os.getenv('PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=False)