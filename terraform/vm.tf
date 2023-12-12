module "instance_template" {
  source  = "terraform-google-modules/vm/google//modules/instance_template"
  version = "~> 10.0"

  project_id           = var.project_id
  region               = var.region
  machine_type         = var.machine_type
  source_image_family  = var.source_image_family
  source_image_project = var.source_image_project
  source_image         = var.source_image
  subnetwork           = module.vpc.subnets_names[0]
  tags                 = ["allow-ssh-ingress"]
  startup_script       = file(var.startup_script_file)
  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_file)}"
  }
  service_account = {
    email  = module.service_accounts.email
    scopes = []
  }
}

module "compute_instance" {
  for_each = { for purpose, zone in var.vm_names_zone_mapping : purpose => zone }

  source  = "terraform-google-modules/vm/google//modules/compute_instance"
  version = "~> 10.0"

  hostname            = each.key
  region              = var.region
  zone                = format("%s-%s", var.region, each.value)
  subnetwork          = module.vpc.subnets_names[0]
  instance_template   = module.instance_template.self_link
  deletion_protection = false

  # Assign public IP only to 'isc-client' instance
  access_config = each.key == "isc-client" ? [{ nat_ip = var.client_public_ip, network_tier = var.network_tier }] : []
}
