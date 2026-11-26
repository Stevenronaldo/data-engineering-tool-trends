locals {
  dataset = {
    "analytics" = {
      dataset_id  = "analytics"
      description = "Dataset for DBT analytics result"
    }
    "raw_github" = {
      dataset_id  = "raw_github"
      description = "Dataset for github data, load by github-loader"
    }
  }
}

resource "google_bigquery_dataset" "bq_dataset" {
  for_each = local.dataset

  project                    = var.gcp_project_id
  location                   = var.gcp_location
  dataset_id                 = each.value.dataset_id
  description                = each.value.description
  delete_contents_on_destroy = false

  lifecycle {
    prevent_destroy = true
  }
}
