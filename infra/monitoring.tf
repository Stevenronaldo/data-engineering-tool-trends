resource "google_monitoring_notification_channel" "email" {
  project      = var.gcp_project_id
  display_name = "My Email"
  type         = "email"
  enabled      = true

  labels = {
    email_address = var.alert_email
  }
}

resource "google_monitoring_alert_policy" "weekly_failed" {
  project      = var.gcp_project_id
  display_name = "dett-weekly-alert"
  combiner     = "OR"
  enabled      = true
  severity     = "CRITICAL"

  notification_channels = [google_monitoring_notification_channel.email.name]

  alert_strategy {
    auto_close           = "1800s"
    notification_prompts = ["OPENED"]
  }

  conditions {
    display_name = "Workflow - Finished execution count"

    condition_threshold {
      filter          = "resource.type = \"workflows.googleapis.com/Workflow\" AND resource.labels.workflow_id = \"dett-weekly\" AND metric.type = \"workflows.googleapis.com/finished_execution_count\" AND metric.labels.status = \"FAILED\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "0s"

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_SUM"
      }

      trigger {
        count = 1
      }
    }
  }

  documentation {
    subject   = "dett-weekly workflow failed"
    mime_type = "text/markdown"
    content   = "The weekly pipeline failed. Open Workflows, then dett-weekly, then Executions, and open the newest run to see which step failed"
  }
}

import {
  to = google_monitoring_notification_channel.email
  id = "projects/data-engineering-tool-trends/notificationChannels/8636603684146396598"
}

import {
  to = google_monitoring_alert_policy.weekly_failed
  id = "projects/data-engineering-tool-trends/alertPolicies/15957482546609389910"
}