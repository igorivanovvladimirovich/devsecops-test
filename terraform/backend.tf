terraform {
  backend "gcs" {
    bucket = "devsecops-test-1772362415-tfstate"
    prefix = "terraform/state"
  }
}
