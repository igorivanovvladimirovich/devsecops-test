resource "google_pubsub_topic" "trivy_reports" {
  name = "trivy-reports"
  message_retention_duration = "259200s"
}

resource "google_pubsub_topic" "apt_detection" {
  name = "apt-detection"
  message_retention_duration = "259200s"
}

resource "google_pubsub_topic" "security_alerts" {
  name = "security-alerts"
  message_retention_duration = "259200s"
}

resource "google_pubsub_subscription" "trivy_reports_sub" {
  name  = "trivy-reports-sub"
  topic = google_pubsub_topic.trivy_reports.name

  ack_deadline_seconds = 60
  message_retention_duration = "259200s"
  retain_acked_messages = false

  expiration_policy {
    ttl = "259200s"
  }
}

resource "google_pubsub_subscription" "apt_detection_sub" {
  name  = "apt-detection-sub"
  topic = google_pubsub_topic.apt_detection.name

  ack_deadline_seconds = 60
  message_retention_duration = "259200s"
  retain_acked_messages = false

  expiration_policy {
    ttl = "259200s"
  }
}
