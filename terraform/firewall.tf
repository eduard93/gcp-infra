module "firewall_rules" {
  source  = "terraform-google-modules/network/google//modules/firewall-rules"
  version = "~> 8.0"

  project_id   = var.project_id
  network_name = module.vpc.network_name

  rules = [{
    name                    = "allow-ssh-ingress"
    description             = "Allow SSH"
    direction               = "INGRESS"
    priority                = null
    ranges                  = ["0.0.0.0/0"]
    source_tags             = null
    source_service_accounts = null
    target_tags             = null
    target_service_accounts = null
    allow = [{
      protocol = "tcp"
      ports    = ["22"]
    }]
    deny = []
    log_config = {
      metadata = "INCLUDE_ALL_METADATA"
    }
    }, {
    name                    = "allow-iris-ingress"
    description             = "Allow connection to IRIS ports"
    direction               = "INGRESS"
    priority                = null
    ranges                  = [var.subnet_ip]
    source_tags             = null
    source_service_accounts = null
    target_tags             = null
    target_service_accounts = null
    allow = [{
      protocol = "tcp"
      ports    = ["1972", "2188", "52773", "53773"]
    }]
    deny = []
    log_config = {
      metadata = "INCLUDE_ALL_METADATA"
    }
    }, {
    name                    = "allow-ping"
    description             = "Allow ping"
    direction               = "INGRESS"
    priority                = null
    ranges                  = [var.subnet_ip]
    source_tags             = null
    source_service_accounts = null
    target_tags             = null
    target_service_accounts = null
    allow = [{
      protocol = "icmp"
    }]
    deny = []
    log_config = {
      metadata = "INCLUDE_ALL_METADATA"
    }
  }]
}