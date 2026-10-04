include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  lab = read_terragrunt_config(find_in_parent_folders("lab.hcl")).locals
}

terraform {
  source = "${get_parent_terragrunt_dir("root")}/modules/image"
}

inputs = {
  libvirt_uri   = local.lab.libvirt_uri
  talos_version = local.lab.talos_version
  extensions    = local.lab.image_extensions
  pool_name     = local.lab.pool.name
  pool_path     = local.lab.pool.path
}
