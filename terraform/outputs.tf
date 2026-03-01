# GKE Outputs
output "cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.autopilot.name
}

output "cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = google_container_cluster.autopilot.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "GKE cluster CA certificate"
  value       = google_container_cluster.autopilot.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "region" {
  description = "GCP region"
  value       = var.region
}

# BigQuery Outputs
output "bigquery_dataset_id" {
  description = "BigQuery dataset ID"
  value       = google_bigquery_dataset.security.dataset_id
}

output "vulnerabilities_table_id" {
  description = "Vulnerabilities table full ID"
  value       = "${var.project_id}.${google_bigquery_dataset.security.dataset_id}.${google_bigquery_table.vulnerabilities.table_id}"
}

output "apt_indicators_table_id" {
  description = "APT indicators table full ID"
  value       = "${var.project_id}.${google_bigquery_dataset.security.dataset_id}.${google_bigquery_table.apt_indicators.table_id}"
}

# Pub/Sub Outputs
output "trivy_reports_topic" {
  description = "Trivy reports Pub/Sub topic"
  value       = google_pubsub_topic.trivy_reports.name
}

output "apt_detection_topic" {
  description = "APT detection Pub/Sub topic"
  value       = google_pubsub_topic.apt_detection.name
}

output "security_alerts_topic" {
  description = "Security alerts Pub/Sub topic"
  value       = google_pubsub_topic.security_alerts.name
}

# Storage Outputs
output "terraform_state_bucket" {
  description = "Terraform state bucket"
  value       = google_storage_bucket.terraform_state.name
}

output "scan_results_bucket" {
  description = "Scan results bucket"
  value       = google_storage_bucket.scan_results.name
}

output "demo_target_bucket" {
  description = "Demo target bucket (for exploit)"
  value       = google_storage_bucket.demo_target.name
}

# Cloud Run Outputs
output "dashboard_url" {
  description = "Security Dashboard URL"
  value       = google_cloud_run_v2_service.security_dashboard.uri
}

# Workload Identity Outputs
output "workload_identity_provider" {
  description = "Workload Identity Provider for GitHub Actions"
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "github_actions_sa_email" {
  description = "GitHub Actions Service Account email"
  value       = google_service_account.github_actions.email
}

# Service Accounts
output "trivy_operator_sa_email" {
  description = "Trivy Operator Service Account"
  value       = google_service_account.github_actions.email
}

output "cloud_functions_sa_email" {
  description = "Cloud Functions Service Account"
  value       = google_service_account.cloud_functions.email
}

# Artifact Registry
output "container_registry" {
  description = "Artifact Registry repository"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.containers.repository_id}"
}

# Instructions
output "connect_to_cluster" {
  description = "Command to connect to GKE cluster"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.autopilot.name} --region ${var.region} --project ${var.project_id}"
}

output "github_secrets_to_set" {
  description = "GitHub secrets configuration"
  value = <<-EOT
    Set these GitHub secrets:
    
    WIF_PROVIDER: ${google_iam_workload_identity_pool_provider.github.name}
    GCP_SA_EMAIL: ${google_service_account.github_actions.email}
    PROJECT_ID: ${var.project_id}
  EOT
}