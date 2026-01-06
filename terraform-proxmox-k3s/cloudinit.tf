data "local_file" "ssh_public_key" {
  filename = var.ssh_public_key
}

locals {
  rendered_yaml = templatefile("${path.module}/cloudinit/cloud-config.yaml.tftpl", {
    ssh_public_key = trimspace(data.local_file.ssh_public_key.content)
  })
}
resource "local_file" "config" {
  filename = "${path.module}/generated_files/${var.prefix}/app_config.yaml"
  content  = local.rendered_yaml
}

# data "cloudinit_config" "cloudinitcfg" {
#   gzip          = false
#   base64_encode = false
#   # part {
#   #   filename     = "hello-script.sh"
#   #   content_type = "text/x-shellscript"
#   #   content = file("${path.module}/cloudinit/hello-script.sh")
#   # }
#   part {
#     filename     = "cloud-config.yaml"
#     content_type = "text/cloud-config"
#     content = local.rendered_yaml
#   }
# }

# see https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config
resource "proxmox_virtual_environment_file" "cloud_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_pve_node_name

  # Better to use source_raw, but still not working as expected
  # source_raw {
  #   data = cloudinit_config.cloudinitcfg.rendered
  #   file_name = "cloud-config.yaml"
  # }
  source_file {
    path      = local_file.config.filename
    file_name = "cloud-config.yaml"
  }
}

resource "local_file" "controller_config" {
  count    = var.controller_count
  filename = "${path.module}/generated_files/${var.prefix}/c${count.index}_app_config.yaml"
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
    file_name = "c${count.index}-meta-data-cloud-config.yaml"
  }
}

resource "local_file" "worker_config" {
  count    = var.worker_count
  filename = "${path.module}/generated_files/${var.prefix}/w${count.index}_app_config.yaml"
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
    file_name = "w${count.index}-meta-data-cloud-config.yaml"
  }
}
