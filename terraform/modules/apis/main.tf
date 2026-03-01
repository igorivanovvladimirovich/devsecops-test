# terraform/modules/apis/main.tf  (new file)

resource "google_project_service" "required_apis" {
  for_each = toset([
    "cloudfunctions.googleapis.com",
    "eventarc.googleapis.com",            # ← missing
    "run.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "pubsub.googleapis.com",
  ])
  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}