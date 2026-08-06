locals {
  required_services = toset([
    "bigquery.googleapis.com",
    "cloudscheduler.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "recommender.googleapis.com",
    "run.googleapis.com",
  ])
}

resource "google_project_service" "required" {
  for_each = local.required_services

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_service_account" "collector" {
  project      = var.project_id
  account_id   = "govengine-collector"
  display_name = "GovEngine collector"

  depends_on = [google_project_service.required]
}

resource "google_service_account" "scheduler" {
  project      = var.project_id
  account_id   = "govengine-scheduler"
  display_name = "GovEngine collector scheduler"

  depends_on = [google_project_service.required]
}

resource "google_project_iam_custom_role" "collector" {
  project     = var.project_id
  role_id     = "govengineCollector"
  title       = "GovEngine Collector (read-only)"
  description = "Read-only inventory, utilization, query execution, and recommendation access for GovEngine."
  permissions = [
    "bigquery.jobs.create",
    "compute.disks.get",
    "compute.disks.list",
    "compute.instances.get",
    "compute.instances.list",
    "compute.machineTypes.get",
    "compute.machineTypes.list",
    "compute.zones.list",
    "monitoring.metricDescriptors.list",
    "monitoring.timeSeries.list",
    "recommender.computeInstanceIdleResourceRecommendations.get",
    "recommender.computeInstanceIdleResourceRecommendations.list",
    "recommender.computeInstanceMachineTypeRecommendations.get",
    "recommender.computeInstanceMachineTypeRecommendations.list",
  ]

  depends_on = [google_project_service.required]
}

resource "google_project_iam_member" "collector" {
  project = var.project_id
  role    = google_project_iam_custom_role.collector.name
  member  = "serviceAccount:${google_service_account.collector.email}"
}

resource "google_bigquery_table_iam_member" "collector_billing_reader" {
  for_each = var.billing_export_table == "" ? toset([]) : toset([var.billing_export_table])

  project    = split(".", each.value)[0]
  dataset_id = split(".", each.value)[1]
  table_id   = split(".", each.value)[2]
  role       = "roles/bigquery.dataViewer"
  member     = "serviceAccount:${google_service_account.collector.email}"
}

resource "google_cloud_run_v2_job" "collector" {
  project             = var.project_id
  name                = "govengine-collector"
  location            = var.region
  deletion_protection = false

  template {
    task_count = 1

    template {
      service_account = google_service_account.collector.email
      max_retries     = 1
      timeout         = "3600s"

      containers {
        image = var.collector_image
        args  = ["--once"]

        resources {
          limits = {
            cpu    = "1"
            memory = "512Mi"
          }
        }

        env {
          name  = "GOVENGINE_URL"
          value = var.govengine_url
        }
        env {
          name  = "GOVENGINE_AUDIENCE"
          value = var.govengine_audience
        }
        env {
          name  = "GOVENGINE_CLOUD_PROVIDER"
          value = "gcp"
        }
        env {
          name  = "GCP_PROJECT_ID"
          value = var.project_id
        }
        env {
          name  = "GCP_BILLING_EXPORT_TABLE"
          value = var.billing_export_table
        }
      }
    }
  }

  depends_on = [
    google_bigquery_table_iam_member.collector_billing_reader,
    google_project_iam_member.collector,
    google_project_service.required,
  ]
}

resource "google_cloud_run_v2_job_iam_member" "scheduler_invoker" {
  project  = var.project_id
  location = google_cloud_run_v2_job.collector.location
  name     = google_cloud_run_v2_job.collector.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.scheduler.email}"
}

resource "google_cloud_scheduler_job" "collector" {
  project   = var.project_id
  region    = var.region
  name      = "govengine-collector-hourly"
  schedule  = "0 * * * *"
  time_zone = "Etc/UTC"

  http_target {
    uri         = "https://run.googleapis.com/v2/projects/${var.project_id}/locations/${google_cloud_run_v2_job.collector.location}/jobs/${google_cloud_run_v2_job.collector.name}:run"
    http_method = "POST"
    body        = base64encode("{}")

    headers = {
      "Content-Type" = "application/json"
    }

    oauth_token {
      service_account_email = google_service_account.scheduler.email
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
    }
  }

  depends_on = [google_cloud_run_v2_job_iam_member.scheduler_invoker]
}
