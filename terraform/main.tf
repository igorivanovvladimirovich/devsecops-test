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
  depends_on   = [module.apis]
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

module "apis" {
  source     = "./modules/apis"
  project_id = var.project_id
}

module "bigquery" {
  source                    = "./modules/bigquery"
  depends_on = [module.apis]
}

module "pubsub" {
  source = "./modules/pubsub"
}

# Закомментировано - деплоим позже через скрипты
# module "functions" {
#   source                    = "./modules/functions"
#   project_id                = var.project_id
#   region                    = var.region
#   scan_results_bucket       = module.storage.scan_results_bucket
#   cloud_functions_sa_email  = module.iam.cloud_functions_sa_email
#   trivy_reports_topic       = module.pubsub.trivy_reports_topic
#   apt_detection_topic       = module.pubsub.apt_detection_topic
#   security_alerts_topic     = module.pubsub.security_alerts_topic
# }

# module "cloudrun" {
#   source             = "./modules/cloudrun"
#   project_id         = var.project_id
#   region             = var.region
#   container_registry = module.storage.container_registry
# }