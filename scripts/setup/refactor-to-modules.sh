#!/bin/bash
set -e
cd terraform

# Backup
cp main-optimized.tf main-optimized.tf.backup

# Create module structure
mkdir -p modules/{network,gke,storage,bigquery,pubsub,iam,functions,cloudrun}

# === NETWORK MODULE ===
cat > modules/network/main.tf <<'EOF'
resource "google_compute_network" "vpc" {
  name                    = "${var.project_id}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project_id}-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.2.0.0/16"
  }
}

resource "google_compute_security_policy" "cloud_armor" {
  name = "${var.project_id}-cloud-armor"

  rule {
    action   = "deny(403)"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["0.0.0.0/0"]
      }
    }
    description = "Block port 31337 (C&C)"
  }

  rule {
    action   = "allow"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }
}
EOF

cat > modules/network/variables.tf <<'EOF'
variable "project_id" {}
variable "region" {}
EOF

cat > modules/network/outputs.tf <<'EOF'
output "network_name" { value = google_compute_network.vpc.name }
output "network_self_link" { value = google_compute_network.vpc.self_link }
output "subnet_name" { value = google_compute_subnetwork.subnet.name }
output "subnet_self_link" { value = google_compute_subnetwork.subnet.self_link }
output "pods_range_name" { value = "pods" }
output "services_range_name" { value = "services" }
EOF

# === GKE MODULE ===
cat > modules/gke/main.tf <<'EOF'
resource "google_container_cluster" "autopilot" {
  name     = var.cluster_name
  location = var.region

  enable_autopilot = true

  network    = var.network_self_link
  subnetwork = var.subnet_self_link

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  logging_config {
    enable_components = ["SYSTEM_COMPONENTS"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
    managed_prometheus { enabled = false }
  }

  release_channel {
    channel = "REGULAR"
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }
}
EOF

cat > modules/gke/variables.tf <<'EOF'
variable "project_id" {}
variable "region" {}
variable "cluster_name" {}
variable "network_self_link" {}
variable "subnet_self_link" {}
variable "pods_range_name" {}
variable "services_range_name" {}
EOF

cat > modules/gke/outputs.tf <<'EOF'
output "cluster_name" { value = google_container_cluster.autopilot.name }
output "cluster_endpoint" { value = google_container_cluster.autopilot.endpoint }
output "cluster_ca_certificate" { 
  value = google_container_cluster.autopilot.master_auth[0].cluster_ca_certificate 
  sensitive = true
}
EOF

# === STORAGE MODULE ===
cat > modules/storage/main.tf <<'EOF'
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
EOF

cat > modules/storage/variables.tf <<'EOF'
variable "project_id" {}
variable "region" {}
EOF

cat > modules/storage/outputs.tf <<'EOF'
output "terraform_state_bucket" { value = google_storage_bucket.terraform_state.name }
output "scan_results_bucket" { value = google_storage_bucket.scan_results.name }
output "demo_target_bucket" { value = google_storage_bucket.demo_target.name }
output "container_registry" { 
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.containers.repository_id}" 
}
EOF

# === BIGQUERY MODULE ===
cat > modules/bigquery/main.tf <<'EOF'
resource "google_bigquery_dataset" "security" {
  dataset_id  = "security_data"
  location    = "US"
  description = "Security scanning and APT detection data"

  default_table_expiration_ms = 259200000

  access {
    role          = "OWNER"
    user_by_email = var.cloud_functions_sa_email
  }
}

resource "google_bigquery_table" "vulnerabilities" {
  dataset_id = google_bigquery_dataset.security.dataset_id
  table_id   = "vulnerabilities"

  time_partitioning {
    type          = "DAY"
    expiration_ms = 259200000
  }

  schema = jsonencode([
    { name = "scan_time", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "resource_namespace", type = "STRING", mode = "REQUIRED" },
    { name = "resource_kind", type = "STRING", mode = "REQUIRED" },
    { name = "resource_name", type = "STRING", mode = "REQUIRED" },
    { name = "vulnerability_id", type = "STRING", mode = "REQUIRED" },
    { name = "package_name", type = "STRING", mode = "NULLABLE" },
    { name = "installed_version", type = "STRING", mode = "NULLABLE" },
    { name = "fixed_version", type = "STRING", mode = "NULLABLE" },
    { name = "severity", type = "STRING", mode = "REQUIRED" },
    { name = "title", type = "STRING", mode = "NULLABLE" },
    { name = "description", type = "STRING", mode = "NULLABLE" },
    { name = "cvss_score", type = "FLOAT", mode = "NULLABLE" },
    { name = "primary_url", type = "STRING", mode = "NULLABLE" }
  ])
}

resource "google_bigquery_table" "apt_indicators" {
  dataset_id = google_bigquery_dataset.security.dataset_id
  table_id   = "apt_indicators"

  time_partitioning {
    type          = "DAY"
    expiration_ms = 259200000
  }

  schema = jsonencode([
    { name = "detection_time", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "indicator_type", type = "STRING", mode = "REQUIRED" },
    { name = "resource_name", type = "STRING", mode = "REQUIRED" },
    { name = "namespace", type = "STRING", mode = "REQUIRED" },
    { name = "details", type = "JSON", mode = "NULLABLE" },
    { name = "risk_score", type = "INTEGER", mode = "REQUIRED" },
    { name = "source", type = "STRING", mode = "REQUIRED" }
  ])
}
EOF

cat > modules/bigquery/variables.tf <<'EOF'
variable "cloud_functions_sa_email" {}
EOF

cat > modules/bigquery/outputs.tf <<'EOF'
output "dataset_id" { value = google_bigquery_dataset.security.dataset_id }
output "vulnerabilities_table_id" { value = google_bigquery_table.vulnerabilities.table_id }
output "apt_indicators_table_id" { value = google_bigquery_table.apt_indicators.table_id }
EOF

# === PUBSUB MODULE ===
cat > modules/pubsub/main.tf <<'EOF'
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
EOF

cat > modules/pubsub/outputs.tf <<'EOF'
output "trivy_reports_topic" { value = google_pubsub_topic.trivy_reports.name }
output "apt_detection_topic" { value = google_pubsub_topic.apt_detection.name }
output "security_alerts_topic" { value = google_pubsub_topic.security_alerts.name }
EOF

# === IAM MODULE ===
cat > modules/iam/main.tf <<'EOF'
resource "google_service_account" "github_actions" {
  account_id   = "github-actions"
  display_name = "GitHub Actions Service Account"
}

resource "google_service_account" "trivy_operator" {
  account_id   = "trivy-operator"
  display_name = "Trivy Operator Service Account"
}

resource "google_service_account" "cloud_functions" {
  account_id   = "cloud-functions-sa"
  display_name = "Cloud Functions Service Account"
}

resource "google_project_iam_member" "github_actions_roles" {
  for_each = toset([
    "roles/editor",
    "roles/iam.serviceAccountUser",
    "roles/iam.workloadIdentityUser"
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_project_iam_member" "trivy_operator_roles" {
  for_each = toset([
    "roles/pubsub.publisher",
    "roles/logging.logWriter"
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.trivy_operator.email}"
}

resource "google_project_iam_member" "cloud_functions_roles" {
  for_each = toset([
    "roles/bigquery.dataEditor",
    "roles/pubsub.publisher",
    "roles/logging.logWriter"
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.cloud_functions.email}"
}

resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions Pool"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub Provider"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "github_wif" {
  service_account_id = google_service_account.github_actions.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_owner}/${var.github_repo}"
}

resource "google_service_account_iam_member" "trivy_wif" {
  service_account_id = google_service_account.trivy_operator.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[trivy-system/trivy-operator]"
}
EOF

cat > modules/iam/variables.tf <<'EOF'
variable "project_id" {}
variable "github_owner" {}
variable "github_repo" {}
EOF

cat > modules/iam/outputs.tf <<'EOF'
output "github_actions_sa_email" { value = google_service_account.github_actions.email }
output "trivy_operator_sa_email" { value = google_service_account.trivy_operator.email }
output "cloud_functions_sa_email" { value = google_service_account.cloud_functions.email }
output "workload_identity_provider" { value = google_iam_workload_identity_pool_provider.github.name }
EOF

# === FUNCTIONS MODULE ===
cat > modules/functions/main.tf <<'EOF'
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
EOF

cat > modules/functions/variables.tf <<'EOF'
variable "project_id" {}
variable "region" {}
variable "scan_results_bucket" {}
variable "cloud_functions_sa_email" {}
variable "trivy_reports_topic" {}
variable "apt_detection_topic" {}
variable "security_alerts_topic" {}
EOF

# === CLOUDRUN MODULE ===
cat > modules/cloudrun/main.tf <<'EOF'
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
EOF

cat > modules/cloudrun/variables.tf <<'EOF'
variable "project_id" {}
variable "region" {}
variable "container_registry" {}
EOF

cat > modules/cloudrun/outputs.tf <<'EOF'
output "dashboard_url" { value = google_cloud_run_v2_service.security_dashboard.uri }
EOF

# === NEW MAIN.TF ===
cat > main.tf <<'EOF'
terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "network" {
  source     = "./modules/network"
  project_id = var.project_id
  region     = var.region
}

module "iam" {
  source       = "./modules/iam"
  project_id   = var.project_id
  github_owner = var.github_owner
  github_repo  = var.github_repo
}

module "storage" {
  source     = "./modules/storage"
  project_id = var.project_id
  region     = var.region
}

module "gke" {
  source               = "./modules/gke"
  project_id           = var.project_id
  region               = var.region
  cluster_name         = var.cluster_name
  network_self_link    = module.network.network_self_link
  subnet_self_link     = module.network.subnet_self_link
  pods_range_name      = module.network.pods_range_name
  services_range_name  = module.network.services_range_name
}

module "bigquery" {
  source                    = "./modules/bigquery"
  cloud_functions_sa_email  = module.iam.cloud_functions_sa_email
}

module "pubsub" {
  source = "./modules/pubsub"
}

module "functions" {
  source                    = "./modules/functions"
  project_id                = var.project_id
  region                    = var.region
  scan_results_bucket       = module.storage.scan_results_bucket
  cloud_functions_sa_email  = module.iam.cloud_functions_sa_email
  trivy_reports_topic       = module.pubsub.trivy_reports_topic
  apt_detection_topic       = module.pubsub.apt_detection_topic
  security_alerts_topic     = module.pubsub.security_alerts_topic
}

module "cloudrun" {
  source             = "./modules/cloudrun"
  project_id         = var.project_id
  region             = var.region
  container_registry = module.storage.container_registry
}
EOF

# === NEW OUTPUTS.TF ===
cat > outputs.tf <<'EOF'
output "cluster_name" { value = module.gke.cluster_name }
output "cluster_endpoint" { value = module.gke.cluster_endpoint, sensitive = true }
output "region" { value = var.region }

output "bigquery_dataset_id" { value = module.bigquery.dataset_id }
output "vulnerabilities_table_id" { 
  value = "${var.project_id}.${module.bigquery.dataset_id}.${module.bigquery.vulnerabilities_table_id}" 
}
output "apt_indicators_table_id" { 
  value = "${var.project_id}.${module.bigquery.dataset_id}.${module.bigquery.apt_indicators_table_id}" 
}

output "trivy_reports_topic" { value = module.pubsub.trivy_reports_topic }
output "apt_detection_topic" { value = module.pubsub.apt_detection_topic }
output "security_alerts_topic" { value = module.pubsub.security_alerts_topic }

output "terraform_state_bucket" { value = module.storage.terraform_state_bucket }
output "scan_results_bucket" { value = module.storage.scan_results_bucket }
output "demo_target_bucket" { value = module.storage.demo_target_bucket }

output "dashboard_url" { value = module.cloudrun.dashboard_url }

output "workload_identity_provider" { value = module.iam.workload_identity_provider }
output "github_actions_sa_email" { value = module.iam.github_actions_sa_email }
output "trivy_operator_sa_email" { value = module.iam.trivy_operator_sa_email }
output "cloud_functions_sa_email" { value = module.iam.cloud_functions_sa_email }

output "container_registry" { value = module.storage.container_registry }

output "connect_to_cluster" {
  value = "gcloud container clusters get-credentials ${module.gke.cluster_name} --region ${var.region} --project ${var.project_id}"
}

output "github_secrets_to_set" {
  value = <<-EOT
    Set these GitHub secrets:
    
    WIF_PROVIDER: ${module.iam.workload_identity_provider}
    GCP_SA_EMAIL: ${module.iam.github_actions_sa_email}
    PROJECT_ID: ${var.project_id}
  EOT
}
EOF

echo "✅ Modules created!"
echo ""
echo "Old file backed up: main-optimized.tf.backup"
echo ""
echo "Run: terraform init -upgrade"