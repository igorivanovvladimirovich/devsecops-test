resource "google_cloud_run_v2_service" "security_dashboard" {
  name     = "security-dashboard"
  location = var.region

  template {
    containers {
      image = "${var.container_registry}/security-dashboard:latest"

      env {
        name  = "PROJECT_ID"
        value = var.project_id
      }
      env {
        name  = "DATASET_ID"
        value = "security_data"
      }

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 2
    }
  }
}

resource "google_cloud_run_v2_service_iam_member" "public_access" {
  name   = google_cloud_run_v2_service.security_dashboard.name
  location = var.region
  role   = "roles/run.invoker"
  member = "allUsers"
}
