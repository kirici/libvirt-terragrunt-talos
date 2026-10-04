include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  lab = read_terragrunt_config(find_in_parent_folders("lab.hcl")).locals
}

terraform {
  source = "${get_parent_terragrunt_dir("root")}/modules/cni"
}

dependency "cluster" {
  config_path = "../cluster"

  mock_outputs = {
    kubernetes_client_configuration = {
      host               = "https://127.0.0.1:6443"
      ca_certificate     = "bW9jaw=="
      client_certificate = "bW9jaw=="
      client_key         = "bW9jaw=="
    }
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate"]
}

inputs = {
  kubernetes          = dependency.cluster.outputs.kubernetes_client_configuration
  cilium_version      = local.lab.cilium_version
  gateway_api_version = local.lab.gateway_api_version
  lb_pool             = local.lab.lb_pool
}
