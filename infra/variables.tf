variable "gcp_location" {
  description = "GCP location for all resources"
  type        = string
  default     = "asia-southeast1"
}

variable "gcp_project_id" {
  description = "GCP project id"
  type        = string
}

variable "alert_email" {
  description = "email used for notification and alert"
  type        = string
}