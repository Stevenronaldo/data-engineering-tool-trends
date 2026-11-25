locals {
  service_accounts = {
    "workflow-runner" = {
      display_name = "DETT Workflow Service Account"
      description  = "Executes Cloud Workflows orchestration"
    }
    "scheduler-invoker" = {
      display_name = "DETT Scheduler Service Account"
      description  = "Triggers scheduled jobs and workflows"
    }
    "github-loader" = {
      display_name = "DETT Loader Service Account"
      description  = "Runs the data ingestion Cloud Run job and add into raw in BigQuery"
    }
    "dbt-runner" = {
      display_name = "DETT dbt Service Account"
      description  = "Runs dbt transformations in BigQuery"
    }
  }
}

resource "google_service_account" "sa" {
  for_each = local.service_accounts

  project      = var.gcp_project_id
  account_id   = each.key
  display_name = each.value.display_name
  description  = each.value.description

  depends_on = [google_project_service.enabled]
}
