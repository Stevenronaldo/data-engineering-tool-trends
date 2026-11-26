resource "google_cloud_scheduler_job" "weekly_trigger" {
  project          = var.gcp_project_id
  region           = var.gcp_location
  name             = "dett-weekly-trigger"
  description      = "Starts the weekly loader and dbt workflow"
  schedule         = "0 1 * * 0"
  time_zone        = "Etc/UTC"
  attempt_deadline = "180s"

  retry_config {
    retry_count          = 1
    min_backoff_duration = "5s"
    max_backoff_duration = "3600s"
    max_doublings        = 5
    max_retry_duration   = "0s"
  }

  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/projects/${var.gcp_project_id}/locations/${var.gcp_location}/workflows/${google_workflows_workflow.weekly.name}/executions"
    body        = base64encode("{}")

    headers = {
      "Content-Type" = "application/json"
    }

    oauth_token {
      service_account_email = google_service_account.sa["scheduler-invoker"].email
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
    }
  }
}

import {
  to = google_cloud_scheduler_job.weekly_trigger
  id = "projects/data-engineering-tool-trends/locations/asia-southeast1/jobs/dett-weekly-trigger"
}