# NAT rather than isolated: nodes must reach container registries and the Image Factory, but nothing outside the host
# can reach the nodes, which is the safe default for a lab. Bridging is handled per NIC in the nodes module.
resource "libvirt_network" "this" {
  name      = var.name
  autostart = true

  forward = {
    mode = "nat"
  }

  bridge = {
    name = var.bridge_name
  }

  domain = {
    name       = var.domain
    local_only = "yes"
  }

  ips = [{
    address = var.gateway
    prefix  = var.prefix
    family  = "ipv4"

    dhcp = {
      ranges = [{
        start = var.dhcp_start
        end   = var.dhcp_end
      }]

      hosts = [
        for name, r in var.reservations : {
          name = name
          mac  = r.mac
          ip   = r.ip
        }
      ]
    }
  }]
}
