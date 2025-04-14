/**
 * Copyright 2023 Google
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.32.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.gcp_region
}

data "google_project" "project" {
}

# Enabling APIs
# Nope

# Set up network
resource "google_compute_network" "vpc_network" {
  name = "terraform-network"  
}

resource "google_compute_firewall" "vpc_network_firewall" {
  name    = "firewall"
  
  network = google_compute_network.vpc_network.name
  
  source_service_accounts = ["${google_service_account.data_pipeline_access.email}"]

  allow {
    protocol = "tcp"
    ports    = ["12345", "12346"]
  }
}

# Setup
resource "google_project_service_identity" "pubsub_service_identity" {
  provider = google-beta
  project = var.project_id
  service = "pubsub.googleapis.com"
}

resource "google_service_account" "data_pipeline_access" {
  project = var.project_id
  account_id = "data-journey-pipeline"
  display_name = "Gaming app data pipeline access"
}

# Set permissions.
resource "google_project_iam_member" "dataflow_admin_role" {
  project = var.project_id
  role = "roles/dataflow.admin"
  member = "serviceAccount:${google_service_account.data_pipeline_access.email}"
}

resource "google_project_iam_member" "dataflow_worker_role" {
  project = var.project_id
  role = "roles/dataflow.worker"
  member = "serviceAccount:${google_service_account.data_pipeline_access.email}"
}

resource "google_project_iam_member" "dataflow_bigquery_role" {
  project = var.project_id
  role = "roles/bigquery.dataEditor"
  member = "serviceAccount:${google_service_account.data_pipeline_access.email}"
}

resource "google_project_iam_member" "dataflow_pub_sub_subscriber" {
  project = var.project_id
  role = "roles/pubsub.subscriber"
  member = "serviceAccount:${google_service_account.data_pipeline_access.email}"
}

resource "google_project_iam_member" "dataflow_pub_sub_viewer" {
  project = var.project_id
  role = "roles/pubsub.viewer"
  member = "serviceAccount:${google_service_account.data_pipeline_access.email}"
}

resource "google_project_iam_member" "dataflow_storage_object_admin" {
  project = var.project_id
  role = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.data_pipeline_access.email}"
}

data "google_compute_default_service_account" "default" {
}

resource "google_project_iam_member" "gce_pub_sub_admin" {
  project = var.project_id
  role = "roles/pubsub.admin"
  member = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

resource "google_project_iam_member" "gce_bq_admin" {
  project = var.project_id
  role = "roles/bigquery.admin"
  member = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

resource "google_project_iam_member" "gce_vertex_agent" {
  project = var.project_id
  role = "roles/aiplatform.serviceAgent"
  member = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

resource "google_project_iam_member" "viewer" {
  project = var.project_id
  role   = "roles/bigquery.metadataViewer"
  member = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "editor" {
  project = var.project_id
  role   = "roles/bigquery.dataEditor"
  member = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "gcs_user" {
  project = var.project_id
  role   = "roles/storage.objectUser"
  member = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

resource "google_artifact_registry_repository" "gcrio" {
  location      = "us"
  repository_id = "gcr.io"
  description   = "docker repository"
  format        = "DOCKER"
}

# Data Simulation
# 1. Create sample data source

resource "google_storage_bucket" "dest_bucket" {
  name          = "example-bucket-name-${var.project_id}"
  location      = "europe-west1"
  force_destroy = true
  uniform_bucket_level_access = true
}

resource "google_bigquery_job" "extract_sample" {
  job_id     = "extract_json_sample_0"

  extract {
    destination_uris = ["${google_storage_bucket.dest_bucket.url}/extract"]

    source_table {
      project_id = "firebase-public-project"
      dataset_id = "analytics_153293282"
      table_id   = "events_20181003"
    }

    destination_format = "NEWLINE_DELIMITED_JSON"
  }
}

# 2. Building a container
resource "null_resource" "build_and_push_docker_image" {
  provisioner "local-exec" {
    command = "gcloud builds submit cloud-run-pubsub-proxy --tag gcr.io/${var.project_id}/pubsub-proxy"
  }
}

# 3. Deploy on Cloud Run
resource "google_cloud_run_service" "proxy_service" {
  name     = "dj-run-service-pubsub-proxy"
  location = "europe-west1"

  template {
    spec {
      containers {
        image = "gcr.io/${var.project_id}/pubsub-proxy"
      }
    }
  }
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location    = google_cloud_run_service.proxy_service.location
  project     = google_cloud_run_service.proxy_service.project
  service     = google_cloud_run_service.proxy_service.name

  policy_data = data.google_iam_policy.noauth.policy_data
}

# Set up P/S topic
resource "google_pubsub_topic" "dj_pubsub_topic" {
  name = "dj-pubsub-topic"
}
