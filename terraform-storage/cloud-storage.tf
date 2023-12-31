module "cloud-storage" {
  source  = "terraform-google-modules/cloud-storage/google//modules/simple_bucket"
  version = "~> 5.0"

  name       = format("isc-mirror-demo-terraform-%s", var.project_id)
  project_id = var.project_id
  location   = var.region
  versioning = true
}
