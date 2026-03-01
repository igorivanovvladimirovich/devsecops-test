output "dataset_id" { value = google_bigquery_dataset.security.dataset_id }
output "vulnerabilities_table_id" { value = google_bigquery_table.vulnerabilities.table_id }
output "apt_indicators_table_id" { value = google_bigquery_table.apt_indicators.table_id }
