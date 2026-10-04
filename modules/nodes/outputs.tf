output "nodes" {
  description = "Consumed by the cluster unit; referencing the domain name orders it after the VMs exist."
  value = {
    for k, n in var.nodes : k => {
      role   = n.role
      ip     = n.ip
      mac    = n.mac
      domain = libvirt_domain.node[k].name
    }
  }
}
