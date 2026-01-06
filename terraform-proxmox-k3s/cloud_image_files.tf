resource "proxmox_virtual_environment_download_file" "arch_cloud_image" {
  content_type = "import"
  datastore_id = "local"
  node_name    = var.proxmox_pve_node_name

  url = var.arch_cloud_image_url
  file_name = "${var.prefix}-archlinux-${basename(var.arch_cloud_image_url)}"
}
