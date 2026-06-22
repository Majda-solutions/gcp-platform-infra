# Repo split notes

This is the **infrastructure repo**.

It contains Terraform and Cloud Run job code:

- Terraform files: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`
- Cloud Run job code: `cloud_run_job/`
- Terraform lock file: `.terraform.lock.hcl`

Generated/local files were removed:

- `.git/`
- `.terraform/`
- `terraform.tfstate`
- `terraform.tfstate.backup`
- `.DS_Store`
