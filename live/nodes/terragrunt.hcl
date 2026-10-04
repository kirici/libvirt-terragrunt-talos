include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  lab = read_terragrunt_config(find_in_parent_folders("lab.hcl")).locals
}

terraform {
  source = "${get_parent_terragrunt_dir("root")}/modules/nodes"
}

dependency "image" {
  config_path = "../image"

  mock_outputs = {
    pool_name        = "mock-pool"
    base_volume_path = "/mock/base.raw"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

dependency "network" {
  config_path = "../network"

  mock_outputs = {
    name = "mock-network"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  libvirt_uri      = local.lab.libvirt_uri
  cluster_name     = local.lab.cluster_name
  pool_name        = dependency.image.outputs.pool_name
  base_volume_path = dependency.image.outputs.base_volume_path
  network_name     = dependency.network.outputs.name
  lan_bridge       = local.lab.lan_bridge
  nodes            = local.lab.nodes
}
