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
