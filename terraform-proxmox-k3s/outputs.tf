output "debug_boolean_value" {
  value = var.legacy_noprefix_cloudconfigfiles
}

output "debug_rendered_filename" {
  value = var.legacy_noprefix_cloudconfigfiles ? "cloud-config.yaml" : "${var.prefix}-user-cloud-config.yaml"
}
