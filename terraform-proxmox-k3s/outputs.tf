output "controller_node_info" {
  description = "List of controller node names and their assigned IP addresses"
  value       = local.controller_nodes
}

output "worker_node_info" {
  description = "List of worker node names and their assigned IP addresses"
  value       = local.worker_nodes
}
