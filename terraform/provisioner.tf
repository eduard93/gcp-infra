resource "null_resource" "client" {
  triggers = {
    always_run = timestamp()
  }

  # This provisioner is added just as a way of waiting until remote instance SSH is up
  # It works because of 'remote-exec' has a retry logic on a refused connection
  connection {
    host        = nonsensitive(module.compute_instance["isc-client"].instances_details[0].network_interface[0].access_config[0].nat_ip)
    user        = var.ssh_user
    port        = var.ssh_port
    agent       = false
    timeout     = "30m"
    private_key = file(var.ssh_private_key_file)
  }

  provisioner "remote-exec" {
    inline = ["# Connected!"]
  }

  provisioner "local-exec" {
    command = <<-EOT
      ssh-add ${var.ssh_private_key_file}
      ansible-playbook -i "$HOST_IP," \
        --extra-vars "ansible_user=$SSH_USER ansible_port=$SSH_PORT project_id=$PROJECT_ID region=$REGION iris_version=$IRIS_VERSION" \
        --ssh-common-args="$SSH_COMMON_ARGS" \
        --timeout "$TIMEOUT" \
        ../ansible/playbook.yml
    EOT
    environment = {
      HOST_IP         = nonsensitive(module.compute_instance["isc-client"].instances_details[0].network_interface[0].access_config[0].nat_ip)
      SSH_COMMON_ARGS = "-o StrictHostKeyChecking=no"
      SSH_USER        = var.ssh_user
      SSH_PORT        = var.ssh_port
      TIMEOUT         = 1800
      PROJECT_ID      = var.project_id
      REGION          = var.region
      IRIS_VERSION    = var.iris_version
    }
  }
}

resource "null_resource" "servers" {
  for_each = { for purpose, zone in var.vm : purpose => zone if purpose != "isc-client" }

  triggers = {
    always_run = timestamp()
  }

  # This provisioner is added just as a way of waiting until remote instance SSH is up
  # It works because of 'remote-exec' has a retry logic on a refused connection
  connection {
    host                = nonsensitive(module.compute_instance[each.key].instances_details[0].network_interface[0].network_ip)
    user                = var.ssh_user
    port                = var.ssh_port
    agent               = true
    timeout             = "30m"
    private_key         = file(var.ssh_private_key_file)
    bastion_host        = nonsensitive(module.compute_instance["isc-client"].instances_details[0].network_interface[0].access_config[0].nat_ip)
    bastion_port        = var.ssh_port
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
        --extra-vars "ansible_user=$SSH_USER ansible_port=$SSH_PORT project_id=$PROJECT_ID region=$REGION iris_version=$IRIS_VERSION" \
        --ssh-common-args="$SSH_COMMON_ARGS" \
        --timeout "$TIMEOUT" \
        ../ansible/playbook.yml
    EOT
    environment = {
      HOST_IP         = nonsensitive(module.compute_instance[each.key].instances_details[0].network_interface[0].network_ip)
      SSH_COMMON_ARGS = "-o StrictHostKeyChecking=no -o ProxyJump=${var.ssh_user}@${nonsensitive(module.compute_instance["isc-client"].instances_details[0].network_interface[0].access_config[0].nat_ip)}:${var.ssh_port}"
      SSH_USER        = var.ssh_user
      SSH_PORT        = var.ssh_port
      TIMEOUT         = 1800
      PROJECT_ID      = var.project_id
      REGION          = var.region
      IRIS_VERSION    = var.iris_version
    }
  }
}
