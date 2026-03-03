import functions_framework
import base64
import json
import gzip
from datetime import datetime
from google.cloud import bigquery
import os

PROJECT_ID = os.getenv('PROJECT_ID')
DATASET_ID = os.getenv('DATASET_ID')
@functions_framework.cloud_event
def process_report(cloud_event):
    """
    Process Trivy vulnerability report from Pub/Sub.
    Извлекает данные и загружает в BigQuery.
    """
    # Декодирование Pub/Sub message
    pubsub_message = base64.b64decode(cloud_event.data["message"]["data"])
    
    try:
        # Trivy использует gzip compression
        decompressed = gzip.decompress(pubsub_message)
        report_data = json.loads(decompressed)
    except:
        # Если не сжато
        report_data = json.loads(pubsub_message)
    
    # Парсинг отчета
    vulnerabilities = parse_trivy_report(report_data)
    
    if vulnerabilities:
        # Загрузка в BigQuery
        upload_to_bigquery(vulnerabilities)
        print(f"Processed {len(vulnerabilities)} vulnerabilities")
    
    return "OK"

def parse_trivy_report(report):
    """Parse Trivy JSON report"""
    vulnerabilities = []
    
    metadata = report.get('metadata', {})
    resource_name = metadata.get('name', 'unknown')
    resource_namespace = metadata.get('namespace', 'default')
    resource_kind = metadata.get('kind', 'Pod')
    
    scan_time = datetime.utcnow().isoformat()
    
    for result in report.get('report', {}).get('vulnerabilities', []):
        vuln = {
            'scan_time': scan_time,
            'resource_namespace': resource_namespace,
            'resource_name': resource_name,
            'resource_kind': resource_kind,
            'vulnerability_id': result.get('vulnerabilityID', ''),
            'severity': result.get('severity', ''),
            'title': result.get('title', ''),
            'package_name': result.get('pkgName', ''),
            'installed_version': result.get('installedVersion', ''),
            'fixed_version': result.get('fixedVersion', ''),
            'cvss_score': result.get('cvss', {}).get('nvd', {}).get('V3Score', 0.0)
        }
        vulnerabilities.append(vuln)
    
    return vulnerabilities

def upload_to_bigquery(vulnerabilities):
    """Upload to BigQuery"""
    client = bigquery.Client(project=PROJECT_ID)
    table_id = f"{PROJECT_ID}.{DATASET_ID}.vulnerabilities"
    
    errors = client.insert_rows_json(table_id, vulnerabilities)
    
    if errors:
        print(f"BigQuery errors: {errors}")
    else:
        print(f"Uploaded {len(vulnerabilities)} rows to BigQuery")