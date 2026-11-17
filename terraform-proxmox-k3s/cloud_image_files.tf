resource "proxmox_download_file" "os_cloud_image" {
  content_type = "import"
  datastore_id = "local"
  node_name    = var.proxmox_pve_node_name

  url       = var.os_cloud_image_url
  file_name = "${var.prefix}-${basename(var.os_cloud_image_url)}"
}

# The download file resource was renamed from proxmox_virtual_environment_download_file
# to proxmox_download_file. Without this move Terraform plans a create/destroy of the
# image file, which changes `import_from` on the VM disks that already imported from it.
# Delete this block once every environment has applied the rename.
moved {
  from = proxmox_virtual_environment_download_file.os_cloud_image
  to   = proxmox_download_file.os_cloud_image
}
