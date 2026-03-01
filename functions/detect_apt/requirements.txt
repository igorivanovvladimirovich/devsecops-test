import base64
import json
import os
from datetime import datetime
from google.cloud import bigquery, pubsub_v1

PROJECT_ID = os.getenv('PROJECT_ID')
DATASET_ID = os.getenv('DATASET_ID')
ALERT_TOPIC = os.getenv('ALERT_TOPIC')
MAGIC_FILE_PATH = os.getenv('MAGIC_FILE_PATH', '/tmp/.magic_file')
CC_PORT = int(os.getenv('CC_PORT', '31337'))

def detect_apt(cloud_event):
    """
    Detect Russian APT indicators:
    1. Magic file in /tmp directory
    2. Back-connection to C&C on port 31337
    3. Crypto mining activity
    """
    # Декодирование сообщения
    pubsub_message = base64.b64decode(cloud_event.data["message"]["data"])
    log_data = json.loads(pubsub_message)
    
    indicators = []
    
    # 1. Проверка magic file
    if check_magic_file(log_data):
        indicators.append({
            'detection_time': datetime.utcnow().isoformat(),
            'indicator_type': 'magic_file',
            'resource_name': log_data.get('pod_name', 'unknown'),
            'namespace': log_data.get('namespace', 'unknown'),
            'details': {'file_path': MAGIC_FILE_PATH},
            'risk_score': 90
        })
    
    # 2. Проверка подозрительного порта
    if check_suspicious_port(log_data):
        indicators.append({
            'detection_time': datetime.utcnow().isoformat(),
            'indicator_type': 'suspicious_port',
            'resource_name': log_data.get('pod_name', 'unknown'),
            'namespace': log_data.get('namespace', 'unknown'),
            'details': {'port': CC_PORT, 'direction': 'outbound'},
            'risk_score': 95
        })
    
    # 3. Проверка crypto mining
    if check_crypto_mining(log_data):
        indicators.append({
            'detection_time': datetime.utcnow().isoformat(),
            'indicator_type': 'crypto_miner',
            'resource_name': log_data.get('pod_name', 'unknown'),
            'namespace': log_data.get('namespace', 'unknown'),
            'details': log_data.get('process_info', {}),
            'risk_score': 100
        })
    
    if indicators:
        # Сохранение в BigQuery
        save_indicators(indicators)
        
        # Отправка alert
        send_alert(indicators)
        
        print(f"🚨 APT DETECTED! {len(indicators)} indicators found")
    
    return "OK"

def check_magic_file(log_data):
    """Check for magic file creation"""
    file_operations = log_data.get('file_operations', [])
    for op in file_operations:
        if MAGIC_FILE_PATH in op.get('path', ''):
            return True
    return False

def check_suspicious_port(log_data):
    """Check for connection to C&C port"""
    connections = log_data.get('network_connections', [])
    for conn in connections:
        if conn.get('destination_port') == CC_PORT:
            return True
    return False

def check_crypto_mining(log_data):
    """Check for crypto mining indicators"""
    processes = log_data.get('processes', [])
    mining_keywords = ['xmrig', 'miner', 'minerd', 'cpuminer', 'ethminer']
    
    for proc in processes:
        proc_name = proc.get('name', '').lower()
        proc_cmd = proc.get('cmdline', '').lower()
        
        if any(keyword in proc_name or keyword in proc_cmd for keyword in mining_keywords):
            return True
    
    # Проверка по CPU usage (>80% длительное время)
    cpu_usage = log_data.get('cpu_usage_percent', 0)
    if cpu_usage > 80:
        return True
    
    return False

def save_indicators(indicators):
    """Save APT indicators to BigQuery"""
    client = bigquery.Client(project=PROJECT_ID)
    table_id = f"{PROJECT_ID}.{DATASET_ID}.apt_indicators"
    
    errors = client.insert_rows_json(table_id, indicators)
    
    if errors:
        print(f"BigQuery errors: {errors}")

def send_alert(indicators):
    """Send alert to Pub/Sub"""
    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(PROJECT_ID, ALERT_TOPIC.split('/')[-1])
    
    alert_message = {
        'alert_type': 'APT_DETECTED',
        'severity': 'CRITICAL',
        'timestamp': datetime.utcnow().isoformat(),
        'indicators': indicators
    }
    
    message_bytes = json.dumps(alert_message).encode('utf-8')
    publisher.publish(topic_path, message_bytes)
    
    print(f"Alert sent to {ALERT_TOPIC}")