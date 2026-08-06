variable "project_id" {
  description = "Google Cloud project to inventory"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must be a valid Google Cloud project ID"
  }
}

variable "region" {
  description = "Region for the collector job and schedule"
  type        = string
  default     = "us-central1"

  validation {
    condition     = can(regex("^[a-z]+-[a-z0-9]+[0-9]$", var.region))
    error_message = "region must be a valid Google Cloud region"
  }
}

variable "display_name" {
  description = "Connection name shown in GovEngine"
  type        = string
  default     = "GCP Production"

  validation {
    condition     = length(trimspace(var.display_name)) >= 1 && length(var.display_name) <= 128
    error_message = "display_name must contain between 1 and 128 characters"
  }
}

variable "collector_image" {
  description = "Public signed GovEngine collector image pinned by digest"
  type        = string

  validation {
    condition     = can(regex("^ghcr\\.io/braventllc/govengine-collector@sha256:[0-9a-f]{64}$", var.collector_image))
    error_message = "collector_image must be the signed GovEngine image pinned by sha256 digest"
  }
}

variable "govengine_url" {
  description = "HTTPS GovEngine origin without user info, path, query, or fragment"
  type        = string
  default     = "https://govengine.ai"

  validation {
    condition     = length(var.govengine_url) <= 2048 && can(regex("^https://([A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?\\.)*[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?(:[1-9][0-9]{0,4})?/?$", var.govengine_url))
    error_message = "govengine_url must be an HTTPS origin with no user info, path, query, or fragment"
  }
}

variable "govengine_audience" {
  description = "HTTPS audience configured as GovEngine CLOUD_IDENTITY_AUDIENCE"
  type        = string
  default     = "https://govengine.ai/cloud-collector"

  validation {
    condition     = length(var.govengine_audience) <= 2048 && can(regex("^https://([A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?\\.)*[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?(:[1-9][0-9]{0,4})?(/[A-Za-z0-9._~/-]*)?$", var.govengine_audience))
    error_message = "govengine_audience must be the HTTPS CLOUD_IDENTITY_AUDIENCE value with no user info, query, or fragment"
  }
}

variable "billing_export_table" {
  description = "Optional project.dataset.table for the detailed BigQuery billing export"
  type        = string
  default     = ""

  validation {
    condition     = var.billing_export_table == "" || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]\\.[A-Za-z_][A-Za-z0-9_]*\\.[A-Za-z_][A-Za-z0-9_]*$", var.billing_export_table))
    error_message = "billing_export_table must be empty or a project.dataset.table identifier"
  }
}
