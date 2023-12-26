variable "project_id" {
  type        = string
  default     = ""
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  default     = "us-west1"
  description = "GCP Region"
}

variable "iris_version" {
  type        = string
  default     = "2023.2.0.221.0"
  description = "IRIS version"
}

variable "name" {
  type        = string
  default     = "isc-mirror"
  description = "VPC name"
}

variable "subnet_ip" {
  type        = string
  default     = "10.0.0.0/24"
  description = "Subnet IP range"
}

variable "machine_type" {
  type        = string
  default     = "n1-standard-1"
  description = "Machine type"
}

variable "source_image_family" {
  type        = string
  default     = "rhel-9"
  description = "OS image family"
}

variable "source_image_project" {
  type        = string
  default     = "rhel-cloud"
  description = "Project where the source image comes from"
}

variable "source_image" {
  type        = string
  default     = "rhel-9-v20231010"
  description = "OS image"
}

variable "vm" {
  type = object({
    isc-primary = object({ zone = string, ip_address = string })
    isc-backup  = object({ zone = string, ip_address = string })
    isc-arbiter = object({ zone = string, ip_address = string })
    isc-client  = object({ zone = string, ip_address = string })
  })
  default = {
    "isc-primary" = { zone = "a", ip_address = "10.0.0.3" },
    "isc-backup"  = { zone = "b", ip_address = "10.0.0.4" },
    "isc-arbiter" = { zone = "c", ip_address = "10.0.0.5" },
    "isc-client"  = { zone = "c", ip_address = "10.0.0.6" },
  }
}

variable "client_public_ip" {
  type        = string
  description = "Client public ip address"
  default     = null
}

variable "network_tier" {
  type        = string
  description = "Network network_tier"
  default     = "PREMIUM"
}

variable "startup_script_file" {
  type        = string
  description = "Startup script file"
  default     = "./templates/vm_init.sh"
}

variable "ssh_user" {
  type        = string
  description = "SSH user"
  default     = "isc"
}

variable "ssh_public_key_file" {
  type        = string
  description = "SSH public key file"
  default     = "./templates/isc_mirror.pub"
}

variable "ssh_private_key_file" {
  type        = string
  description = "SSH local private key file"
  default     = "~/.ssh/isc_mirror"
}
