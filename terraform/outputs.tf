output "cluster_name" { 
  value = module.gke.cluster_name 
}

output "cluster_endpoint" { 
  value     = module.gke.cluster_endpoint
  sensitive = true 
}

output "region" { 
  value = var.region 
}

output "bigquery_dataset_id" { 
  value = module.bigquery.dataset_id 
}

output "trivy_reports_topic" { 
  value = module.pubsub.trivy_reports_topic 
}

output "workload_identity_provider" { 
  value = module.iam.workload_identity_provider 
}

output "github_actions_sa_email" { 
  value = module.iam.github_actions_sa_email 
}

output "container_registry" { 
  value = module.storage.container_registry 
}

output "scan_results_bucket" { 
  value = module.storage.scan_results_bucket 
}

output "connect_to_cluster" {
  value = "gcloud container clusters get-credentials ${module.gke.cluster_name} --region ${var.region} --project ${var.project_id}"
}

output "github_secrets_to_set" {
  value = <<-EOT
    gh secret set WIF_PROVIDER -b "${module.iam.workload_identity_provider}"
    gh secret set GCP_SA_EMAIL -b "${module.iam.github_actions_sa_email}"
    gh secret set PROJECT_ID -b "${var.project_id}"
  EOT
}