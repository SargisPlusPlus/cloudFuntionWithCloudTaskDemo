variable "region" {
  default = "us-central1"
}

variable "location" {
  default = "us-central"
}

variable "project" {
  default = "direct-raceway-285603"
}

provider "google" {
  project = var.project
  version = "3.33.0"
}

provider "google-beta" {
  project = var.project
  version = "3.33.0"
}

resource "google_app_engine_application" "app" {
  location_id = var.location
  project     = var.project
}

resource "google_project_service" "cloudfunctions" {
  service = "cloudfunctions.googleapis.com"
}

resource "google_storage_bucket" "demo_71815285" {
  name          = "demo-71815285-${var.project}"
  project       = var.project
  location      = var.region
  storage_class = "REGIONAL"

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_cloudfunctions_function" "my-function" {
  name        = "myFunction"
  description = "Cloud Function Demo"
  runtime     = "nodejs10"
  region      = var.region

  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.demo_71815285.name
  source_archive_object = "cloud-functions/main.zip"
  entry_point           = "myFunction"
  trigger_http          = true

  environment_variables = {
    GCLOUD_PROJECT               = var.project
    LOCATION                     = var.region
    NODE_ENV                     = "production"
  }

  labels = {
    "deployment-tool" = "cli-gcloud"
  }

  depends_on = [
    google_project_service.cloudfunctions,
    google_app_engine_application.app,
  ]
}

resource "google_cloudfunctions_function_iam_member" "default-invoker" {
  project        = var.project
  region         = var.region
  cloud_function = google_cloudfunctions_function.my-function.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

resource "google_project_service" "cloudtasks" {
  service = "cloudtasks.googleapis.com"
}

resource "google_cloud_tasks_queue" "my-queue" {
  name     = "my-queue"
  location = "us-central1"
  rate_limits {
    max_dispatches_per_second = 5
    max_concurrent_dispatches = 3
  }
  retry_config {
    max_attempts = -1
  }
  depends_on = [
    google_project_service.cloudtasks,
    google_app_engine_application.app
  ]
}
