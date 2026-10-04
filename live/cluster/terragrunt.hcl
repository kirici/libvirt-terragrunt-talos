include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  lab = read_terragrunt_config(find_in_parent_folders("lab.hcl")).locals
}

terraform {
  source = "${get_parent_terragrunt_dir("root")}/modules/cluster"
}

dependency "image" {
  config_path = "../image"

  mock_outputs = {
    installer_image = "factory.talos.dev/installer/mock:v0.0.0"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

# Taking the node list from the nodes unit, rather than lab.hcl directly, is what orders this unit after the VMs exist.
dependency "nodes" {
  config_path = "../nodes"

  mock_outputs = {
    nodes = {
      cp-1 = { role = "controlplane", ip = "10.0.0.10" }
    }
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

inputs = {
  cluster_name       = local.lab.cluster_name
  talos_version      = local.lab.talos_version
  kubernetes_version = local.lab.kubernetes_version
  installer_image    = dependency.image.outputs.installer_image
  nodes              = dependency.nodes.outputs.nodes
}
