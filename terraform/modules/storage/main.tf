resource "google_storage_bucket" "terraform_state" {
  name          = "${var.project_id}-tfstate"
  location      = var.region
  force_destroy = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 5
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket" "scan_results" {
  name          = "${var.project_id}-scan-results"
  location      = var.region
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 3
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket" "demo_target" {
  name          = "${var.project_id}-demo-target"
  location      = var.region
  force_destroy = true
}

resource "google_artifact_registry_repository" "containers" {
  repository_id = "devsecops-containers"
  location      = var.region
  format        = "DOCKER"
}
