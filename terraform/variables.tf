variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

variable "cluster_name" {
  description = "GKE Cluster name"
  type        = string
  default     = "devsecops-gke"
}

variable "github_owner" {
  description = "GitHub repository owner/organization"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "alert_email" {
  description = "Email for security alerts"
  type        = string
}

variable "apt_magic_file" {
  description = "Path to magic file for APT detection"
  type        = string
  default     = "/tmp/.magic_file"
}

variable "apt_cc_port" {
  description = "C&C port for APT detection"
  type        = number
  default     = 31337
}