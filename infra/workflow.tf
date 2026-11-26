resource "google_workflows_workflow" "weekly" {
  project         = var.gcp_project_id
  region          = var.gcp_location
  name            = "dett-weekly"
  service_account = google_service_account.sa["workflow-runner"].email
  source_contents = file("${path.module}/../workflows/weekly_pipeline.yaml")

  lifecycle {
    prevent_destroy = true
  }
}
