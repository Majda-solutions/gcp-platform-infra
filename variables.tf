variable "project_id" {
  description = "Google Cloud project ID"
  type        = string
  default     = "iam-project-498112"
}

variable "region" {
  description = "Cloud Run and BigQuery location"
  type        = string
  default     = "us-central1"
}

variable "location" {
  description = "Bucket and Data Catalog location"
  type        = string
  default     = "US"
}

variable "bq_dataset_id" {
  description = "BigQuery dataset name for raw and staging tables"
  type        = string
  default     = "analytics"
}

variable "cloud_run_job_name" {
  description = "Cloud Run job name for the data copy and hash pipeline"
  type        = string
  default     = "employee-data-copy-job"
}

variable "landing_bucket_name" {
  description = "Landing bucket name where source data arrives"
  type        = string
  default     = "majda-landing-iam-project-498112-20260622-1909"
}

variable "raw_bucket_name" {
  description = "Raw bucket name where processed data is stored"
  type        = string
  default     = "majda-raw-iam-project-498112-20260622-1909"
}
