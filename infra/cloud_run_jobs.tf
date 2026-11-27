resource "google_cloud_run_v2_job" "loader" {
  project             = var.gcp_project_id
  location            = var.gcp_location
  name                = "dett-loader"
  deletion_protection = true

  template {
    task_count = 1

    template {
      service_account = google_service_account.sa["github-loader"].email
      timeout         = "600s"
      max_retries     = 0

      containers {
        image = "asia-southeast1-docker.pkg.dev/data-engineering-tool-trends/dett-images/loader:latest"

        resources {
          limits = {
            cpu    = "1000m"
            memory = "512Mi"
          }
        }

        env {
          name  = "BQ_DATASET"
          value = google_bigquery_dataset.bq_dataset["raw_github"].dataset_id
        }
        env {
          name  = "GCP_PROJECT"
          value = var.gcp_project_id
        }
        env {
          name = "GITHUB_TOKEN"
          value_source {
            secret_key_ref {
              secret  = google_secret_manager_secret.dett-secret.secret_id
              version = "latest"
            }
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].template[0].containers[0].image,
      client,
      client_version,
    ]
  }
}

resource "google_cloud_run_v2_job" "dbt" {
  project             = var.gcp_project_id
  location            = var.gcp_location
  name                = "dett-dbt"
  deletion_protection = true

  template {
    task_count = 1

    template {
      service_account = google_service_account.sa["dbt-runner"].email
      timeout         = "600s"
      max_retries     = 0

      containers {
        image = "asia-southeast1-docker.pkg.dev/data-engineering-tool-trends/dett-images/dbt:latest"

        resources {
          limits = {
            cpu    = "1000m"
            memory = "1Gi"
          }
        }

        env {
          name  = "DBT_DATASET"
          value = google_bigquery_dataset.bq_dataset["analytics"].dataset_id
        }
        env {
          name  = "GCP_LOCATION"
          value = var.gcp_location
        }
        env {
          name  = "GCP_PROJECT"
          value = var.gcp_project_id
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].template[0].containers[0].image,
      client,
      client_version,
    ]
  }
}
