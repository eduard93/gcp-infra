resource "null_resource" "client" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      ssh-add ${var.ssh_private_key_file}
      ansible-playbook -i "$HOST_IP," \
        --extra-vars ansible_user="$SSH_USER" \
        --ssh-common-args="$SSH_COMMON_ARGS" \
        --timeout "$TIMEOUT" \
        ../ansible/playbook.yml
    EOT
    environment = {
      HOST_IP         = nonsensitive(module.compute_instance["isc-client"].instances_details[0].network_interface[0].access_config[0].nat_ip)
      SSH_COMMON_ARGS = "-o StrictHostKeyChecking=no"
      SSH_USER        = var.ssh_user
      TIMEOUT         = 120
    }
  }
}

resource "null_resource" "servers" {
  # for_each = toset([ "isc-primary", "isc-secondary", "isc-agent" ])
  for_each = { for purpose, zone in var.vm_names_zone_mapping : purpose => zone if purpose != "isc-client" }

  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      ssh-add ${var.ssh_private_key_file}
      ansible-playbook -i "$HOST_IP," \
        --extra-vars ansible_user="$SSH_USER" \
        --ssh-common-args="$SSH_COMMON_ARGS" \
        --timeout "$TIMEOUT" \
        ../ansible/playbook.yml
    EOT
    environment = {
      HOST_IP         = nonsensitive(module.compute_instance[each.key].instances_details[0].network_interface[0].network_ip)
      SSH_COMMON_ARGS = "-o StrictHostKeyChecking=no -o ProxyJump=${nonsensitive(module.compute_instance["isc-client"].instances_details[0].network_interface[0].access_config[0].nat_ip)}"
      SSH_USER        = var.ssh_user
      TIMEOUT         = 120
    }
  }
}
