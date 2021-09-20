terraform {
  required_providers {
    google = {
      version = "~> 3.50.0"
    }
  }
}

provider "google" {
  region = var.region
}


locals {
  name = "bucketlist"
  services_to_enable = [
    "compute.googleapis.com",
    "container.googleapis.com",
  ]
}
data "google_client_config" "default" {}

# provider "kubernetes" {
#   host                   = "https://${module.gke.endpoint}"
#   token                  = data.google_client_config.default.access_token
#   cluster_ca_certificate = base64decode(module.gke.ca_certificate)
# }

data "google_compute_subnetwork" "subnetwork" {
  name    = google_compute_subnetwork.main.name
  project = google_project.main.project_id
  region  = var.region
}


resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}


resource "google_project" "main" {
  name            = local.name
  project_id      = "${local.name}-${random_string.suffix.result}"
  billing_account = var.billing_account
}

resource "google_service_account" "gke_sa" {
  project      = google_project.main.project_id
  account_id   = "${local.name}-${random_string.suffix.result}"
  display_name = local.name
}

resource "google_project_service" "service" {
  for_each = toset(local.services_to_enable)
  # This resource is instantiated serveral times
  project            = google_project.main.project_id
  service            = each.value
  disable_on_destroy = false
}

# module "gke-project" {
#   source  = "terraform-google-modules/project-factory/google"
#   version = "~> 10.1"

#   name              = "${local.name}-${random_string.suffix.result}"
#   random_project_id = true
#   #   org_id            = var.org_id
#   #   folder_id         = var.folder_id
#   billing_account = var.billing_account

#   activate_apis = [
#     "cloudkms.googleapis.com",
#     "cloudresourcemanager.googleapis.com",
#     "container.googleapis.com",
#     #"pubsub.googleapis.com",
#     #"serviceusage.googleapis.com",
#     #"storage-api.googleapis.com",
#     #"gkehub.googleapis.com",
#   ]
#   #   activate_api_identities = [
#   #     {
#   #       api   = "container.googleapis.com"
#   #       roles = ["roles/cloudkms.cryptoKeyEncrypterDecrypter", "roles/container.serviceAgent"]
#   #     },
#   #   ]
# }


resource "google_compute_network" "main" {
  project                 = google_project.main.project_id
  name                    = "${local.name}-${random_string.suffix.result}"
  auto_create_subnetworks = false
  depends_on = [
    google_project_service.service
  ]
}

resource "google_compute_subnetwork" "main" {
  project       = google_project.main.project_id
  name          = "${local.name}-${random_string.suffix.result}"
  ip_cidr_range = "10.0.0.0/17"
  region        = var.region
  network       = google_compute_network.main.self_link

  secondary_ip_range {
    range_name    = "${local.name}-pods-${random_string.suffix.result}"
    ip_cidr_range = "192.168.0.0/18"
  }

  secondary_ip_range {
    range_name    = "${local.name}-services-${random_string.suffix.result}"
    ip_cidr_range = "192.168.64.0/18"
  }
}


module "gke" {
  source                 = "terraform-google-modules/kubernetes-engine/google"
  project_id             = google_project.main.project_id
  name                   = "${local.name}-${random_string.suffix.result}"
  regional               = false
  region                 = var.region
  zones                  = var.zones
  network                = google_compute_network.main.name
  subnetwork             = google_compute_subnetwork.main.name
  ip_range_pods          = google_compute_subnetwork.main.secondary_ip_range[0].range_name
  ip_range_services      = google_compute_subnetwork.main.secondary_ip_range[1].range_name
  create_service_account = false
  service_account        = google_service_account.gke_sa.email

  master_authorized_networks = var.master_authorized_networks

  node_pools = [
    {
      name            = "default-node-pool"
      machine_type    = "e2-small"
      node_locations  = var.zones[0]
      min_count       = 1
      max_count       = 1
      local_ssd_count = 0
      disk_size_gb    = 30
  }]

  depends_on = [
    google_project_service.service
  ]
}
