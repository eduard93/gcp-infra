module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 9.0"

  project_id   = var.project_id
  network_name = var.name
  routing_mode = "REGIONAL"

  subnets = [
    {
      subnet_name   = var.region
      subnet_region = var.region
      subnet_ip     = var.subnet_ip
    }
  ]
}
