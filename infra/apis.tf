locals {
  apis = toset([
    "bigquery.googleapis.com",
    "run.googleapis.com",
    "workflows.googleapis.com",
    "workflowexecutions.googleapis.com",
    "cloudscheduler.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "monitoring.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "serviceusage.googleapis.com"
  ])
}

resource "google_project_service" "enabled" {
  for_each = local.apis

  project         = var.gcp_project_id
  service         = each.key
  deletion_policy = "ABANDON"

}
