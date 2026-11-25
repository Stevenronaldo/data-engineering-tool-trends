resource "google_project_iam_member" "workflow-runner" {
  for_each = toset([
    "roles/run.viewer",
    "roles/logging.logWriter",
  ])

  project = var.gcp_project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.sa["workflow-runner"].email}"
}

resource "google_project_iam_member" "scheduler-invoker" {
  project = var.gcp_project_id
  role    = "roles/workflows.invoker"
  member  = "serviceAccount:${google_service_account.sa["scheduler-invoker"].email}"
}

resource "google_project_iam_member" "dbt-runner" {
  project = var.gcp_project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.sa["dbt-runner"].email}"
}

resource "google_project_iam_member" "github-loader" {
  project = var.gcp_project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.sa["github-loader"].email}"
}

resource "google_bigquery_dataset_iam_member" "github_dataset_roles" {
  project    = var.gcp_project_id
  dataset_id = "raw_github"
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.sa["github-loader"].email}"
}

locals {
  dbt_dataset_permissions = {
    "dbt-read-raw" = {
      dataset_id = "raw_github"
      role       = "roles/bigquery.dataViewer"
    }
    "dbt-write-analytics" = {
      dataset_id = "analytics"
      role       = "roles/bigquery.dataEditor"
    }
  }
}

resource "google_bigquery_dataset_iam_member" "dbt_dataset_roles" {
  for_each = local.dbt_dataset_permissions

  project    = var.gcp_project_id
  dataset_id = each.value.dataset_id
  role       = each.value.role
  member     = "serviceAccount:${google_service_account.sa["dbt-runner"].email}"
}

resource "google_secret_manager_secret_iam_member" "github_token_access" {
  project   = var.gcp_project_id
  secret_id = "github-token"
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.sa["github-loader"].email}"
}

resource "google_cloud_run_v2_job_iam_member" "workflow_invoke_jobs" {
  for_each = toset([
    "dett-loader",
    "dett-dbt",
  ])

  project  = var.gcp_project_id
  location = var.gcp_location
  name     = each.key
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.sa["workflow-runner"].email}"
}