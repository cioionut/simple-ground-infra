data "local_file" "ssh_public_key" {
  filename = var.ssh_public_key
}

locals {
  rendered_yaml = templatefile("${path.module}/cloudinit/cloud-config.yaml.tftpl", {
    ssh_public_key = trimspace(data.local_file.ssh_public_key.content)
  })
}
resource "local_file" "config" {
  filename = "${path.module}/generated_files/${var.prefix}/user-cloud-config.yaml"
  content  = local.rendered_yaml
}

locals {
  # Calculate the filename here so it's a static string by the time it reaches the resource
  target_cloud_config_name = var.legacy_noprefix_cloudconfigfiles ? "cloud-config.yaml" : "${var.prefix}-user-cloud-config.yaml"
}
# see https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config
resource "proxmox_virtual_environment_file" "cloud_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_pve_node_name
  source_file {
    path      = local_file.config.filename
    file_name = local.target_cloud_config_name
  }
}

resource "local_file" "controller_config" {
  count    = var.controller_count
  filename = "${path.module}/generated_files/${var.prefix}/c${count.index}-meta-data-cloud-config.yaml"
  content  = <<-EOF
    ---
    # cloud-config
    local-hostname: c${count.index}
    EOF
}

resource "proxmox_virtual_environment_file" "controller_meta_data_cloud_config" {
  count        = var.controller_count
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_pve_node_name

  source_file {
    path      = local_file.controller_config[count.index].filename
    file_name = var.legacy_noprefix_cloudconfigfiles ? "c${count.index}-meta-data-cloud-config.yaml" : "${var.prefix}-c${count.index}-meta-data-cloud-config.yaml"
  }
}

resource "local_file" "worker_config" {
  count    = var.worker_count
  filename = "${path.module}/generated_files/${var.prefix}/w${count.index}-meta-data-cloud-config.yaml"
  content  = <<-EOF
    ---
    # cloud-config
    local-hostname: w${count.index}
    EOF
}

resource "proxmox_virtual_environment_file" "worker_meta_data_cloud_config" {
  count        = var.worker_count
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_pve_node_name

  source_file {
    path      = local_file.worker_config[count.index].filename
    file_name = var.legacy_noprefix_cloudconfigfiles ? "w${count.index}-meta-data-cloud-config.yaml" : "${var.prefix}-w${count.index}-meta-data-cloud-config.yaml"
  }
}
