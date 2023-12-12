terraform {
  required_version = "> 1.1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.5.0"
    }

    # ansible = {
    #   source  = "ansible/ansible"
    #   version = "~> 1.1.0"
    # }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
