output "registration_manifest" {
  description = "Paste this identifier-only manifest into GovEngine"
  value = jsonencode({
    provider     = "gcp"
    principal    = google_service_account.collector.unique_id
    accountScope = var.project_id
    displayName  = var.display_name
  })
}

output "run_now_url" {
  description = "Open the collector job execution page"
  value       = "https://console.cloud.google.com/run/jobs/details/${var.region}/${google_cloud_run_v2_job.collector.name}/executions?project=${var.project_id}"
}

output "logs_url" {
  description = "Open this project's Cloud Logging query page"
  value       = "https://console.cloud.google.com/logs/query?project=${var.project_id}"
}
