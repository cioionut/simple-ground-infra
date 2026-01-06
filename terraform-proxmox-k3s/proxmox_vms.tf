locals {
  controller_nodes = [
    for i in range(var.controller_count) : {
      name    = "c${i}"
      address = cidrhost(var.cluster_node_network, var.cluster_node_network_first_controller_hostnum + i)
    }
  ]
  worker_nodes = [
    for i in range(var.worker_count) : {
      name    = "w${i}"
      address = cidrhost(var.cluster_node_network, var.cluster_node_network_first_worker_hostnum + i)
    }
  ]
}

# see https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm for more details.
resource "proxmox_virtual_environment_vm" "controller" {
  count       = var.controller_count
  vm_id       = var.cluster_node_network_first_controller_hostnum * 10 + count.index
  name        = "${var.prefix}-${local.controller_nodes[count.index].name}"
  node_name   = var.proxmox_pve_node_name
  tags        = sort(["terraform", "k3s-controller"])
  machine     = "q35"
  bios        = "ovmf"
  description = "Managed by Terraform"
  cpu {
    cores = 4
    type  = "x86-64-v2-AES" # recommended for modern CPUs
  }
  memory {
    dedicated = 4 * 1024
  }
  network_device {
    bridge = "vmbr0"
  }
  agent {
    enabled = true
    trim    = true
  }
  initialization {
    datastore_id = var.datastore_id
    ip_config {
      ipv4 {
        address = "${local.controller_nodes[count.index].address}/24"
        gateway = var.cluster_node_network_gateway
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id
    meta_data_file_id = proxmox_virtual_environment_file.controller_meta_data_cloud_config[count.index].id
  }
  efi_disk {
    datastore_id = var.datastore_id
    type         = "4m"
  }
  disk {
    datastore_id = var.datastore_id
    import_from  = proxmox_virtual_environment_download_file.arch_cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 20
  }
}

resource "proxmox_virtual_environment_vm" "worker" {
  count       = var.worker_count
  vm_id       = var.cluster_node_network_first_worker_hostnum * 10 + count.index
  name        = "${var.prefix}-${local.worker_nodes[count.index].name}"
  node_name   = var.proxmox_pve_node_name
  tags        = sort(["terraform", "k3s-worker"])
  machine     = "q35"
  bios        = "ovmf"
  description = "Managed by Terraform"
  cpu {
    cores = 8
    type  = "x86-64-v2-AES" # recommended for modern CPUs
  }
  memory {
    dedicated = var.worker_count == 0 ? 64 * 1024 : 8 * 1024
  }
  dynamic "hostpci" {
    # This block will only be rendered if count.index is 0 (the first worker)
    for_each = (count.index == 0 && var.use_gpu) ? [1] : []
    content {
      device = "hostpci0"
      # id = "0000:05:00.0"
      mapping = "nv3090"
      pcie    = true
      rombar  = true
    }
  }
  network_device {
    bridge = "vmbr0"
  }
  # should be true if qemu agent is not installed / enabled on the VM
  # stop_on_destroy = true
  agent {
    # NOTE: The agent is installed and enabled as part of the cloud-init configuration in the template VM, see cloud-config.tf
    # The working agent is *required* to retrieve the VM IP addresses.
    # If you are using a different cloud-init configuration, or a different clone source
    # that does not have the qemu-guest-agent installed, you may need to disable the `agent` below and remove the `vm_ipv4_address` output.
    # See https://registry.terraform.io/providers/bpg/proxmox/latest/docs/resources/virtual_environment_vm#qemu-guest-agent for more details.
    enabled = true
    trim    = true
  }
  initialization {
    datastore_id = var.datastore_id
    ip_config {
      ipv4 {
        address = "${local.worker_nodes[count.index].address}/24"
        gateway = var.cluster_node_network_gateway
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id
    meta_data_file_id = proxmox_virtual_environment_file.worker_meta_data_cloud_config[count.index].id
  }
  efi_disk {
    datastore_id = var.datastore_id
    type         = "4m"
  }
  disk {
    datastore_id = var.datastore_id
    import_from  = proxmox_virtual_environment_download_file.arch_cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = (count.index == 0 && var.use_gpu) ? 120 : 20
  }
}

# output "arch_vm_ipv4_address" {
#   value = proxmox_virtual_environment_vm.arch_vm.ipv4_addresses[1][0]
# }
