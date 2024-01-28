terraform {
  required_version = "> 1.1.0"

  backend "gcs" {}

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.12.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
