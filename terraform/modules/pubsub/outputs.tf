output "trivy_reports_topic" { value = google_pubsub_topic.trivy_reports.name }
output "apt_detection_topic" { value = google_pubsub_topic.apt_detection.name }
output "security_alerts_topic" { value = google_pubsub_topic.security_alerts.name }
