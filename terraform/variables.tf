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

variable "vm_names_zone_mapping" {
  type = object({
    isc-primary   = string
    isc-secondary = string
    isc-agent     = string
    isc-client    = string
  })
  default = {
    "isc-primary"   = "a",
    "isc-secondary" = "b",
    "isc-agent"     = "c",
    "isc-client"    = "c"
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
