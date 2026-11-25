resource "google_artifact_registry_repository" "dett-images" {
  project       = var.gcp_project_id
  location      = var.gcp_location
  repository_id = "dett-images"
  format        = "DOCKER"
  description   = "Container images for the data engineering tool trends pipeline"
}
