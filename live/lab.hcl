# Single source of truth for the lab. Units read this via read_terragrunt_config and pick what they need.
locals {
  cluster_name  = "talos-lab"
  libvirt_uri   = "qemu:///system"
  talos_version = "v1.13.9"

  # Empty means "use the Kubernetes version this Talos release ships". Pin it only if Cilium's support matrix lags.
  kubernetes_version = ""

  # Official Image Factory extension names, e.g. ["siderolabs/qemu-guest-agent"]. Left empty because the guest agent
  # also needs a virtio channel on the domain, which is not wired up yet.
  image_extensions = []

  cilium_version      = "1.20.0"
  gateway_api_version = "v1.6.1"

  pool = {
    name = "talos-lab"
    path = "/var/lib/libvirt/images/talos-lab"
  }

  network = {
    name       = "talos-lab"
    bridge     = "virbr-talos"
    gateway    = "10.5.0.1"
    prefix     = 24
    domain     = "talos.lab"
    dhcp_start = "10.5.0.100"
    dhcp_end   = "10.5.0.199"
  }

  # Outside the DHCP range so a LoadBalancer IP can never collide with a leased address.
  lb_pool = {
    start = "10.5.0.200"
    stop  = "10.5.0.250"
  }

  # Name of an existing host bridge (e.g. br0) to add a second NIC on the LAN. Empty keeps the cluster NAT-only.
  lan_bridge = ""

  # Fixed MACs make the DHCP reservations, and therefore the IPs Talos is configured with, deterministic.
  nodes = {
    cp-1 = {
      role       = "controlplane"
      ip         = "10.5.0.10"
      mac        = "52:54:00:5a:10:01"
      vcpu       = 2
      memory_mib = 4096
      disk_gib   = 20
    }
    worker-1 = {
      role       = "worker"
      ip         = "10.5.0.21"
      mac        = "52:54:00:5a:10:21"
      vcpu       = 2
      memory_mib = 8192
      disk_gib   = 40
    }
    worker-2 = {
      role       = "worker"
      ip         = "10.5.0.22"
      mac        = "52:54:00:5a:10:22"
      vcpu       = 2
      memory_mib = 8192
      disk_gib   = 40
    }
  }
}
