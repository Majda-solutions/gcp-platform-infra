# 🧩 Employee Data Platform — Google Cloud
 
# Project Overview

This project implements an end-to-end data pipeline on Google Cloud Platform.

It demonstrates how data is ingested, processed, de-identified, stored, and prepared for analytics using managed Google Cloud services. The project also includes the cloud infrastructure required to support the pipeline, with all resources provisioned using Terraform (Infrastructure as Code).

The repository is organized into two main areas:

- **Data Pipeline** – Describes the flow of data from ingestion through processing to analytics.
- **Cloud Infrastructure** – Describes the Google Cloud resources and infrastructure used to build and operate the pipeline.
- **DevOps** – Describes the Infrastructure as Code, containerization, and deployment workflow used to automate the solution.

## Data Flow

![Employee Data Pipeline](https://raw.githubusercontent.com/Majda-solutions/gcp-platform-infra/a6ee3be5e5aee20965d1aeef2c0ed6a40653aae8/dataflow%20pipeline.png)

## Data Engineering Pipeline

The pipeline implements an ETL workflow that ingests employee data, applies data de-identification, and prepares the dataset for analytics.

| Stage | Description |
|--------|-------------|
| **Extract** | Employee data is uploaded as a CSV file to a Cloud Storage landing bucket. |
| **Transform** | A Python application running as a Cloud Run Job reads the file, invokes Cloud DLP to HMAC-hash the `employee_id`, and writes the transformed dataset to a raw bucket. |
| **Load** | BigQuery exposes the processed dataset through an External Table and creates a staging table for analytical workloads. |

---

## Google Cloud Infrastructure

The pipeline is built entirely with managed Google Cloud services.

| Component | Purpose |
|-----------|---------|
| **Cloud Storage** | Stores both the source and processed datasets. |
| **Cloud Run Jobs** | Executes the containerized Python ETL application. |
| **Cloud DLP** | Applies HMAC-based pseudonymization to sensitive employee identifiers. |
| **BigQuery** | Provides an analytics platform using an External Table and staging table. |
| **Artifact Registry** | Stores the Docker container image used by Cloud Run. |
| **IAM** | Controls access between Google Cloud services using least-privilege permissions. |
| **Terraform** | Provisions all cloud resources using Infrastructure as Code (IaC). |
| **Docker** | Packages the Python application into a portable container image. |

---

## DevOps

The project follows DevOps practices to automate infrastructure provisioning, application packaging, and deployment.

| Component | Purpose |
|-----------|---------|
| **Terraform** | Provisions and manages all Google Cloud resources using Infrastructure as Code (IaC). |
| **GitHub Actions** | Automates infrastructure validation and deployment through CI/CD pipelines. |
| **Docker** | Packages the Python ETL application into a portable container image. |
| **Artifact Registry** | Stores and versions Docker images for deployment to Cloud Run. |
| **Cloud Build** | Builds the Docker image before it is stored in Artifact Registry. |
| **Git** | Provides version control for infrastructure and application source code. |

### DevOps Workflow

1. Infrastructure is defined in Terraform.
2. Source code is versioned in GitHub.
3. GitHub Actions validates and deploys infrastructure changes.
4. The Python application is containerized with Docker.
5. Cloud Build builds the container image.
6. The image is stored in Artifact Registry.
7. Cloud Run executes the latest container image as a serverless batch job.
