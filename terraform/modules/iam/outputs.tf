output "github_actions_sa_email" { value = google_service_account.github_actions.email }
output "trivy_operator_sa_email" { value = google_service_account.trivy_operator.email }
output "cloud_functions_sa_email" { value = google_service_account.cloud_functions.email }
output "workload_identity_provider" {
  value = google_iam_workload_identity_pool_provider.github.name
}
