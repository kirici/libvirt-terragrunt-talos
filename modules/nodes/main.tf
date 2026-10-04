# Thin qcow2 overlays on the shared raw Talos image, so three nodes cost one image on disk plus their own writes.
resource "libvirt_volume" "disk" {
  for_each = var.nodes

  name     = "${var.cluster_name}-${each.key}.qcow2"
  pool     = var.pool_name
  capacity = each.value.disk_gib * 1024 * 1024 * 1024

  target = {
    format = {
      type = "qcow2"
    }
  }

  backing_store = {
    path = var.base_volume_path
    format = {
      type = "raw"
    }
  }
}

resource "libvirt_domain" "node" {
  for_each = var.nodes

  name        = "${var.cluster_name}-${each.key}"
  type        = "kvm"
  memory      = each.value.memory_mib
  memory_unit = "MiB"
  vcpu        = each.value.vcpu
  running     = true
  autostart   = true

  # Talos requires at least x86-64-v2, which QEMU's default CPU model does not advertise, so the nodes would not boot.
  cpu = {
    mode = "host-passthrough"
  }

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
  }

  devices = {
    disks = [{
      driver = {
        type = "qcow2"
      }
      source = {
        volume = {
          pool   = var.pool_name
          volume = libvirt_volume.disk[each.key].name
        }
      }
      target = {
        dev = "vda"
        bus = "virtio"
      }
    }]

    # The NAT NIC comes first so Talos picks it as the primary address. The optional LAN NIC only gets DHCP from the
    # LAN and is not used by the cluster itself.
    interfaces = concat(
      [{
        type  = "network"
        model = { type = "virtio" }
        mac   = { address = each.value.mac }
        source = {
          network = { network = var.network_name }
        }
      }],
      var.lan_bridge == "" ? [] : [{
        type  = "bridge"
        model = { type = "virtio" }
        source = {
          bridge = { bridge = var.lan_bridge }
        }
      }],
    )
  }
}
