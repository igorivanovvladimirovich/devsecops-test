# modules/bigquery/main.tf

resource "google_bigquery_dataset" "security" {
  dataset_id                  = "security_data"
  location                    = "US"
  description                 = "Security scanning and APT detection data"
  default_table_expiration_ms = 259200000
}

resource "google_bigquery_table" "vulnerabilities" {
  dataset_id = google_bigquery_dataset.security.dataset_id
  table_id   = "vulnerabilities"

  depends_on = [google_bigquery_dataset.security]  # ← ADD THIS

  time_partitioning {
    type          = "DAY"
    expiration_ms = 259200000
  }

  schema = jsonencode([
    { name = "scan_time",           type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "resource_namespace",  type = "STRING",    mode = "REQUIRED" },
    { name = "resource_kind",       type = "STRING",    mode = "REQUIRED" },
    { name = "resource_name",       type = "STRING",    mode = "REQUIRED" },
    { name = "vulnerability_id",    type = "STRING",    mode = "REQUIRED" },
    { name = "package_name",        type = "STRING",    mode = "NULLABLE" },
    { name = "installed_version",   type = "STRING",    mode = "NULLABLE" },
    { name = "fixed_version",       type = "STRING",    mode = "NULLABLE" },
    { name = "severity",            type = "STRING",    mode = "REQUIRED" },
    { name = "title",               type = "STRING",    mode = "NULLABLE" },
    { name = "description",         type = "STRING",    mode = "NULLABLE" },
    { name = "cvss_score",          type = "FLOAT",     mode = "NULLABLE" },
    { name = "primary_url",         type = "STRING",    mode = "NULLABLE" }
  ])
}

resource "google_bigquery_table" "apt_indicators" {
  dataset_id = google_bigquery_dataset.security.dataset_id
  table_id   = "apt_indicators"

  depends_on = [google_bigquery_dataset.security]  # ← ADD THIS

  time_partitioning {
    type          = "DAY"
    expiration_ms = 259200000
  }

  schema = jsonencode([
    { name = "detection_time",  type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "indicator_type",  type = "STRING",    mode = "REQUIRED" },
    { name = "resource_name",   type = "STRING",    mode = "REQUIRED" },
    { name = "namespace",       type = "STRING",    mode = "REQUIRED" },
    { name = "details",         type = "JSON",      mode = "NULLABLE" },
    { name = "risk_score",      type = "INTEGER",   mode = "REQUIRED" },
    { name = "source",          type = "STRING",    mode = "REQUIRED" }
  ])
}