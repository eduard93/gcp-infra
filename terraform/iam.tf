module "roles" {
  source  = "terraform-google-modules/iam/google//modules/custom_role_iam"
  version = "~> 7.0"

  target_id   = var.project_id
  role_id     = "isc.demo.vm"
  title       = "ISC Demo VM"
  description = "Role for ISC Mirror VM demo"
  permissions = flatten(regexall("\"(.*)\"", file("./templates/instance-permissions.yaml")))
  members     = []
}

module "service_accounts" {
  source  = "terraform-google-modules/service-accounts/google"
  version = "~> 4.0"

  project_id   = var.project_id
  names        = ["isc-mirror-vm"]
  display_name = "ISC Mirror VM"
  description  = "ISC Mirror Virtual Machine"
  project_roles = [
    "${var.project_id}=>projects/${var.project_id}/roles/${module.roles.custom_role_id}"
  ]
}
