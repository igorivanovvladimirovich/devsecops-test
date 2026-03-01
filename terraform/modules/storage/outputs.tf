output "terraform_state_bucket" { value = google_storage_bucket.terraform_state.name }
output "scan_results_bucket" { value = google_storage_bucket.scan_results.name }
output "demo_target_bucket" { value = google_storage_bucket.demo_target.name }
output "container_registry" { 
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.containers.repository_id}" 
}
