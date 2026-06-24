provider "google" {
  project               = var.project_id
  region                = var.region
  billing_project       = var.project_id
  user_project_override = true
}

resource "google_project_service" "services" {
  for_each = toset([
    "storage.googleapis.com",
    "bigquery.googleapis.com",
    "run.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "dlp.googleapis.com",
    "datacatalog.googleapis.com",
    "iam.googleapis.com"
  ])
  service = each.key
}

resource "random_password" "dlp_hmac_key" {
  length  = 32
  special = false
}

#Create budket
resource "google_storage_bucket" "landing" {
  name     = var.landing_bucket_name
  location = var.location

  uniform_bucket_level_access = true
  force_destroy               = true
}

#Create budket
resource "google_storage_bucket" "raw" {
  name     = var.raw_bucket_name
  location = var.location

  uniform_bucket_level_access = true
  force_destroy               = true
}

#creates a DLP de-identification template that automatically finds the employee_id column and replaces its values with a hash.
resource "google_data_loss_prevention_deidentify_template" "employee_id_hmac" {
  parent       = "projects/${var.project_id}/locations/global"
  display_name = "employee_id_hmac"

  deidentify_config {
    record_transformations {
      field_transformations {
        fields {
          name = "employee_id"
        }

        primitive_transformation {
          crypto_hash_config {
            crypto_key {
              transient {
                name = "employee-id-hmac-key"
              }
            }
          }
        }
      }
    }
  }
}
/*
#creates a Data Catalog taxonomy, which acts like a folder for organizing policy tags that are used to protect sensitive columns in BigQuery.
resource "google_data_catalog_taxonomy" "sensitive_data_taxonomy" {
  display_name = "sensitive_data"
  description  = "Taxonomy for column-level security on sensitive employee data."
  project      = var.project_id

}
#policy tag called salary_sensitive inside the sensitive_data taxonomy, which can be attached to the salary column so BigQuery
resource "google_data_catalog_policy_tag" "salary_sensitive" {
  taxonomy     = google_data_catalog_taxonomy.sensitive_data_taxonomy.id
  display_name = "salary_sensitive"
  description  = "Protect salary values for unauthorized users."
}
*/

#BigQuery dataset, which is like a folder that stores your BigQuery tables
resource "google_bigquery_dataset" "main" {
  dataset_id = var.bq_dataset_id
  project    = var.project_id
  location   = var.location
}


#BigQuery external table called raw_employees_ext that reads CSV files directly from the raw bucket instead of storing the data inside BigQuery.
resource "google_bigquery_table" "raw_employees_ext" {
  dataset_id = google_bigquery_dataset.main.dataset_id
  table_id   = "raw_employees_ext"

  external_data_configuration {
    autodetect    = false
    source_format = "CSV"
    source_uris   = ["gs://${google_storage_bucket.raw.name}/*.csv"]

    csv_options {
      quote             = "\""
      skip_leading_rows = 1
    }

    schema = jsonencode([
      {
        name        = "employee_id"
        type        = "STRING"
        mode        = "REQUIRED"
        description = ""
      },
      {
        name        = "first_name"
        type        = "STRING"
        mode        = "NULLABLE"
        description = ""
      },
      {
        name        = "last_name"
        type        = "STRING"
        mode        = "NULLABLE"
        description = ""
      },
      {
        name        = "salary"
        type        = "NUMERIC"
        mode        = "NULLABLE"
        description = ""
      },
      {
        name        = "department"
        type        = "STRING"
        mode        = "NULLABLE"
        description = ""
      },
      {
        name        = "hire_date"
        type        = "DATE"
        mode        = "NULLABLE"
        description = ""
      }
    ])
  }
}
#------ Service Account -----------
#Creates a service account that the Cloud Run job will use to authenticate and access Google Cloud resources.
resource "google_service_account" "cloud_run_job_sa" {
  account_id   = "employee-hash-job-sa"
  display_name = "Cloud Run job service account for employee hashing"
}
#Gives the service account permission to use Google DLP for hashing and de-identifying data.
resource "google_project_iam_member" "service_account_dlp" {
  project = var.project_id
  role    = "roles/dlp.user"
  member  = "serviceAccount:${google_service_account.cloud_run_job_sa.email}"
}
# Gives the service account permission to create and write files to Cloud Storage, such as the raw bucket.
resource "google_project_iam_member" "service_account_storage_viewer" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.cloud_run_job_sa.email}"
}
# grants the Cloud Run service account permission to create and upload files to Cloud Storage.
resource "google_project_iam_member" "service_account_storage_creator" {
  project = var.project_id
  role    = "roles/storage.objectCreator"
  member  = "serviceAccount:${google_service_account.cloud_run_job_sa.email}"
}
#creates an Artifact Registry repository where Docker images are stored. The Cloud Run job uses a Docker image
resource "google_artifact_registry_repository" "cloud_run_repo" {
  provider      = google
  location      = var.region
  repository_id = "cloud-run-jobs"
  description   = "Docker repository for Cloud Run job image"
  format        = "DOCKER"
}
# creates a Cloud Run job that runs a Docker container to read files from the landing bucket, 
#hash the employee_id values using the DLP template
resource "google_cloud_run_v2_job" "employee_hash_job" {
  name     = var.cloud_run_job_name
  location = var.region

  template {
    template {
      containers {

        image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.cloud_run_repo.repository_id}/${var.cloud_run_job_name}:latest"

        env {
          name  = "LANDING_BUCKET"
          value = google_storage_bucket.landing.name
        }

        env {
          name  = "RAW_BUCKET"
          value = google_storage_bucket.raw.name
        }

        env {
          name  = "DLP_TEMPLATE_NAME"
          value = google_data_loss_prevention_deidentify_template.employee_id_hmac.name
        }

        env {
          name  = "PROJECT_ID"
          value = var.project_id
        }
      }

      service_account = google_service_account.cloud_run_job_sa.email
    }
  }
}
