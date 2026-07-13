resource "proxmox_download_file" "os_cloud_image" {
  content_type = "import"
  datastore_id = "local"
  node_name    = var.proxmox_pve_node_name

  url = var.os_cloud_image_url
  file_name = "${var.prefix}-${basename(var.os_cloud_image_url)}"
}
