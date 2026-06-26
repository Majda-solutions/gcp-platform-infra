# CI/CD setup for the infrastructure repo

This repo now has two GitHub Actions workflows.

## 1. Terraform CI/CD

File:

```text
.github/workflows/terraform.yml
```

What it does:

- checks Terraform formatting
- runs `terraform init`
- runs `terraform validate`
- runs `terraform plan`
- runs `terraform apply` only when you start the workflow manually

This is safer because infrastructure should not be changed automatically on every push.

## 2. Docker build and Cloud Run Job deploy

File:

```text
.github/workflows/deploy-cloud-run-job.yml
```

What it does when you push changes inside `cloud_run_job/`:

- builds the Docker image
- pushes it to Artifact Registry
- updates the Cloud Run Job to use the new image

## GitHub secrets you need

Add these in GitHub:

Repository → Settings → Secrets and variables → Actions → New repository secret

```text
GCP_PROJECT_ID
GCP_SA_KEY
```

`GCP_PROJECT_ID` should be:

```text
iam-project-498112
```

`GCP_SA_KEY` should be the JSON key for a Google Cloud service account that can:

- use Artifact Registry
- update Cloud Run Jobs
- run Terraform
- read/write the needed Google Cloud resources

## Important

This CI/CD deploys code and infrastructure. It does not upload new employee CSV files.

For new CSV files, you still upload to the landing bucket unless you later add a storage trigger or scheduler.
