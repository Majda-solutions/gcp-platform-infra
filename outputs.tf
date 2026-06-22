output "landing_bucket_name" {
  value = google_storage_bucket.landing.name
}

output "raw_bucket_name" {
  value = google_storage_bucket.raw.name
}

output "dlp_template_name" {
  value = google_data_loss_prevention_deidentify_template.employee_id_hmac.name
}

output "bigquery_dataset" {
  value = google_bigquery_dataset.main.dataset_id
}

output "raw_external_table" {
  value = "${google_bigquery_dataset.main.dataset_id}.${google_bigquery_table.raw_employees_ext.table_id}"
}

output "cloud_run_job_name" {
  value = google_cloud_run_v2_job.employee_hash_job.name
}

output "policy_tag_salary_sensitive" {
  value = google_data_catalog_policy_tag.salary_sensitive.name
}
