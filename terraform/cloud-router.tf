module "compute_router" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "~> 6.0"

  project = var.project_id
  name    = var.name
  network = module.vpc.network_name
  region  = var.region

  nats = [{
    name = var.name
  }]
}