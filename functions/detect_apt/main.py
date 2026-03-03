import functions_framework
import base64
import json
import os
from datetime import datetime, timezone
from google.cloud import bigquery, pubsub_v1

PROJECT_ID = os.getenv('PROJECT_ID')
DATASET_ID = os.getenv('DATASET_ID')
ALERT_TOPIC = os.getenv('ALERT_TOPIC')
@functions_framework.cloud_event
def detect_apt(cloud_event):
    pubsub_message = base64.b64decode(cloud_event.data["message"]["data"])
    log_data = json.loads(pubsub_message)

    print(f"Received message: {json.dumps(log_data)}")

    indicators = []
    now = datetime.now(timezone.utc).isoformat()

    # Формат от apt-detector (прямой алерт)
    if "indicator_type" in log_data:
        indicators.append({
            "detection_time": log_data.get("detection_time", now),
            "indicator_type": log_data.get("indicator_type", "unknown"),
            "resource_name":  log_data.get("resource_name", "unknown"),
            "namespace":      log_data.get("namespace", "unknown"),
            "details":        json.dumps(log_data.get("details", {})),
            "risk_score":     int(log_data.get("risk_score", 0)),
            "source":         log_data.get("source", "apt-detector"),
        })

    # Старый формат (структурированный Falco/агент)
    else:
        if check_magic_file(log_data):
            indicators.append({
                "detection_time": now,
                "indicator_type": "magic_file",
                "resource_name":  log_data.get("pod_name", "unknown"),
                "namespace":      log_data.get("namespace", "unknown"),
                "details":        json.dumps({"file_path": "/tmp/.magic_file"}),
                "risk_score":     90,
                "source":         "cloud-function",
            })

        if check_suspicious_port(log_data):
            indicators.append({
                "detection_time": now,
                "indicator_type": "suspicious_port",
                "resource_name":  log_data.get("pod_name", "unknown"),
                "namespace":      log_data.get("namespace", "unknown"),
                "details":        json.dumps({"port": 31337}),
                "risk_score":     95,
                "source":         "cloud-function",
            })

        if check_crypto_mining(log_data):
            indicators.append({
                "detection_time": now,
                "indicator_type": "crypto_miner",
                "resource_name":  log_data.get("pod_name", "unknown"),
                "namespace":      log_data.get("namespace", "unknown"),
                "details":        json.dumps(log_data.get("process_info", {})),
                "risk_score":     100,
                "source":         "cloud-function",
            })

    if indicators:
        save_indicators(indicators)
        send_alert(indicators)
        print(f"🚨 APT DETECTED! {len(indicators)} indicators saved to BigQuery")
    else:
        print("No APT indicators found in message")

    return "OK"


def check_magic_file(log_data):
    for op in log_data.get("file_operations", []):
        if "/tmp/.magic_file" in op.get("path", ""):
            return True
    return False


def check_suspicious_port(log_data):
    for conn in log_data.get("network_connections", []):
        if conn.get("destination_port") == 31337:
            return True
    return False


def check_crypto_mining(log_data):
    keywords = ["xmrig", "miner", "minerd", "cpuminer", "ethminer"]
    for proc in log_data.get("processes", []):
        name = proc.get("name", "").lower()
        cmd  = proc.get("cmdline", "").lower()
        if any(k in name or k in cmd for k in keywords):
            return True
    return log_data.get("cpu_usage_percent", 0) > 80


def save_indicators(indicators):
    client = bigquery.Client(project=PROJECT_ID)
    table_id = f"{PROJECT_ID}.{DATASET_ID}.apt_indicators"
    errors = client.insert_rows_json(table_id, indicators)
    if errors:
        print(f"BigQuery errors: {errors}")
    else:
        print(f"✅ Saved {len(indicators)} indicators to BigQuery")


def send_alert(indicators):
    if not ALERT_TOPIC:
        return
    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(PROJECT_ID, ALERT_TOPIC.split("/")[-1])
    alert = {
        "alert_type": "APT_DETECTED",
        "severity":   "CRITICAL",
        "timestamp":  datetime.now(timezone.utc).isoformat(),
        "indicators": indicators,
    }
    publisher.publish(topic_path, json.dumps(alert).encode("utf-8"))
    print(f"Alert sent to {ALERT_TOPIC}")