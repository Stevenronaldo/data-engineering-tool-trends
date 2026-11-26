resource "google_secret_manager_secret" "dett-secret" {
  secret_id           = "github-token"
  deletion_protection = true
  replication {
    auto {}
  }
  lifecycle {
    prevent_destroy = true
  }
}
