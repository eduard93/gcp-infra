module "external_ip" {
  count   = var.enable_mirror_public_ip ? 1 : 0
  source  = "terraform-google-modules/address/google"
  version = "~> 3.0"

  project_id   = var.project_id
  region       = var.region
  address_type = "EXTERNAL"
  names        = [var.name]
}
