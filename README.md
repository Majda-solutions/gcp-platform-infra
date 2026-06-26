# terraform-gcp-infra - Terraform GCP Setup

This repository sets up Google Cloud infrastructure for:

- `landing bucket`: the initial location where source data lands
- `raw bucket`: the next location where processed data is copied
- DLP `CryptoHashConfig` HMAC for `employee_id`
- Cloud Run Job that copies CSV files from landing to raw and hashes `employee_id`
- BigQuery dataset and external table over the raw bucket
- Data Catalog policy tag for protecting a column in BigQuery

## Init

```
terraform init. 
```

## Plan and apply

```
terraform apply -var="project_id=YOUR_GCP_PROJECT_ID"
```

## Build the Cloud Run job

From the `cloud_run_job` directory:

```
gcloud builds submit --config cloudbuild.yaml --substitutions=_IMAGE=LOCATION-docker.pkg.dev/YOUR_GCP_PROJECT_ID/cloud-run-jobs/employee-data-copy-job:latest
```

## Run the job

Once the image is published and the job is created:

```
gcloud beta run jobs execute employee-data-copy-job --region us-central1 --project YOUR_GCP_PROJECT_ID
```
Test
