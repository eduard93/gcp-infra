resource "null_resource" "client" {
  triggers = {
    always_run = timestamp()
  }

  # This provisioner is added just as a way of waiting until remote instance SSH is up
  # It works because of 'remote-exec' has a retry logic on a refused connection
  connection {
    host        = nonsensitive(module.compute_instance["isc-client"].instances_details[0].network_interface[0].access_config[0].nat_ip)
    user        = var.ssh_user
    agent       = false
    timeout     = "3m"
    private_key = file(var.ssh_private_key_file)
  }

  provisioner "remote-exec" {
    inline = ["# Connected!"]
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
  for_each = { for purpose, zone in var.vm_names_zone_mapping : purpose => zone if purpose != "isc-client" }

  triggers = {
    always_run = timestamp()
  }

  # This provisioner is added just as a way of waiting until remote instance SSH is up
  # It works because of 'remote-exec' has a retry logic on a refused connection
  connection {
    host                = nonsensitive(module.compute_instance[each.key].instances_details[0].network_interface[0].network_ip)
    user                = var.ssh_user
    agent               = true
    timeout             = "3m"
    private_key         = file(var.ssh_private_key_file)
    bastion_host        = nonsensitive(module.compute_instance["isc-client"].instances_details[0].network_interface[0].access_config[0].nat_ip)
    bastion_port        = 22
    bastion_user        = var.ssh_user
    bastion_private_key = file(var.ssh_private_key_file)
  }

  provisioner "remote-exec" {
    inline = ["# Connected!"]
  }

  provisioner "local-exec" {
    command = <<-EOT
      ssh-add ${var.ssh_private_key_file}
      ansible-playbook -i "$HOST_IP," \
        --extra-vars "ansible_user=$SSH_USER" \
        --ssh-common-args="$SSH_COMMON_ARGS" \
        --timeout "$TIMEOUT" \
        ../ansible/playbook.yml
    EOT
    environment = {
      HOST_IP         = nonsensitive(module.compute_instance[each.key].instances_details[0].network_interface[0].network_ip)
      SSH_COMMON_ARGS = "-o StrictHostKeyChecking=no -o ProxyJump=${var.ssh_user}@${nonsensitive(module.compute_instance["isc-client"].instances_details[0].network_interface[0].access_config[0].nat_ip)}"
      SSH_USER        = var.ssh_user
      TIMEOUT         = 120
    }
  }
}
