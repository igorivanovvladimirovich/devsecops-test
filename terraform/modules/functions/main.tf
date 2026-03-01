resource "google_cloudfunctions2_function" "process_trivy" {
  name     = "process-trivy-reports"
  location = var.region

  build_config {
    runtime     = "python311"
    entry_point = "process_report"
    source {
      storage_source {
        bucket = var.scan_results_bucket
        object = "functions/process-trivy.zip"
      }
    }
  }

  service_config {
    max_instance_count = 3
    min_instance_count = 0
    available_memory   = "256M"
    timeout_seconds    = 60
    service_account_email = var.cloud_functions_sa_email

    environment_variables = {
      PROJECT_ID = var.project_id
      DATASET_ID = "security_data"
    }
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = "projects/${var.project_id}/topics/${var.trivy_reports_topic}"
  }
}

resource "google_cloudfunctions2_function" "detect_apt" {
  name     = "detect-apt-indicators"
  location = var.region

  build_config {
    runtime     = "python311"
    entry_point = "detect_apt"
    source {
      storage_source {
        bucket = var.scan_results_bucket
        object = "functions/detect-apt.zip"
      }
    }
  }

  service_config {
    max_instance_count = 3
    min_instance_count = 0
    available_memory   = "256M"
    timeout_seconds    = 60
    service_account_email = var.cloud_functions_sa_email

    environment_variables = {
      PROJECT_ID  = var.project_id
      DATASET_ID  = "security_data"
      ALERT_TOPIC = var.security_alerts_topic
    }
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = "projects/${var.project_id}/topics/${var.apt_detection_topic}"
  }
}
