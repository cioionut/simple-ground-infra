variable "arch_cloud_image_url" {
  type    = string
  default = "https://fastly.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-cloudimg.qcow2"
}

# k3s cluster variables
variable "cluster_node_network" {
  description = "The IP network of the cluster nodes"
  type        = string
}

variable "cluster_node_network_first_controller_hostnum" {
  description = "The hostnum of the first controller host"
  type        = number
  default     = 50
}

variable "cluster_node_network_first_worker_hostnum" {
  description = "The hostnum of the first worker host"
  type        = number
  default     = 60
}

variable "cluster_node_network_gateway" {
  description = "The IP network gateway of the cluster nodes"
  type        = string
}

variable "controller_count" {
  type    = number
  default = 1
  validation {
    condition     = var.controller_count >= 0
    error_message = "Must be 1 or more."
  }
}

variable "datastore_id" {
  type    = string
  default = "local-lvm"
}

variable "legacy_noprefix_cloudconfigfiles" {
  type = bool
  default = false
}

variable "prefix" {
  type    = string
  default = "k3s"
}

variable "proxmox_pve_node_address" {
  type = string
}

variable "proxmox_pve_node_name" {
  type    = string
}

variable "ssh_public_key" {
  type        = string
  description = "Path to the SSH public key file to be used for VM access"
}

variable "use_gpu" {
  type    = bool
  default = false
}

variable "worker_count" {
  type    = number
  default = 1
  validation {
    condition     = var.worker_count >= 0
    error_message = "Must be 1 or more."
  }
}
