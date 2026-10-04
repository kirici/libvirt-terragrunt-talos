include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  lab = read_terragrunt_config(find_in_parent_folders("lab.hcl")).locals
}

terraform {
  source = "${get_parent_terragrunt_dir("root")}/modules/network"
}

inputs = {
  libvirt_uri = local.lab.libvirt_uri
  name        = local.lab.network.name
  bridge_name = local.lab.network.bridge
  gateway     = local.lab.network.gateway
  prefix      = local.lab.network.prefix
  domain      = local.lab.network.domain
  dhcp_start  = local.lab.network.dhcp_start
  dhcp_end    = local.lab.network.dhcp_end
  reservations = {
    for name, n in local.lab.nodes : name => { mac = n.mac, ip = n.ip }
  }
}
