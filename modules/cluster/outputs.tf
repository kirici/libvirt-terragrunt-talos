output "kubeconfig_raw" {
  value     = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive = true
}

output "kubernetes_client_configuration" {
  description = "Structured credentials for the cni unit's helm and kubectl providers (values are base64)."
  value       = talos_cluster_kubeconfig.this.kubernetes_client_configuration
  sensitive   = true
}

output "talosconfig" {
  value     = data.talos_client_configuration.this.talos_config
  sensitive = true
}

output "cluster_endpoint" {
  value = local.cluster_endpoint
}
