provider "talos" {}

locals {
  controlplane_ips = [for n in var.nodes : n.ip if n.role == "controlplane"]
  bootstrap_ip     = local.controlplane_ips[0]
  cluster_endpoint = "https://${local.bootstrap_ip}:6443"

  patches = {
    for name, n in var.nodes : name => [
      yamlencode({
        machine = {
          network = { hostname = name }
          install = {
            disk  = var.install_disk
            image = var.installer_image
          }
        }
        cluster = {
          # Cilium replaces both the default CNI and kube-proxy, so neither may start before it is installed.
          network = { cni = { name = "none" } }
        }
      }),
      # kube-proxy only exists on control plane nodes, so the setting is only valid there.
      n.role == "controlplane" ? yamlencode({
        cluster = { proxy = { disabled = true } }
      }) : yamlencode({}),
    ]
  }
}

resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

data "talos_machine_configuration" "node" {
  for_each = var.nodes

  cluster_name       = var.cluster_name
  cluster_endpoint   = local.cluster_endpoint
  machine_type       = each.value.role
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version == "" ? null : var.kubernetes_version
  config_patches     = local.patches[each.key]
  docs               = false
  examples           = false
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = local.controlplane_ips
  nodes                = [for n in var.nodes : n.ip]
}

# A freshly started VM needs a moment before the Talos API answers; waiting here gives a clear timeout message instead
# of a connection error buried in the provider.
resource "terraform_data" "wait_for_api" {
  for_each = var.nodes

  triggers_replace = [each.value.ip]

  provisioner "local-exec" {
    command = "bash ${path.module}/scripts/wait-for-port.sh ${each.value.ip} 50000 300"
  }
}

resource "talos_machine_configuration_apply" "node" {
  for_each = var.nodes

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.node[each.key].machine_configuration
  node                        = each.value.ip
  endpoint                    = each.value.ip

  depends_on = [terraform_data.wait_for_api]
}

resource "talos_machine_bootstrap" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.bootstrap_ip
  endpoint             = local.bootstrap_ip

  depends_on = [talos_machine_configuration_apply.node]
}

# No health wait on purpose: with the CNI disabled the nodes cannot become Ready until the cni unit has run, so a health
# check here would always time out.
resource "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.bootstrap_ip
  endpoint             = local.bootstrap_ip

  depends_on = [talos_machine_bootstrap.this]
}
