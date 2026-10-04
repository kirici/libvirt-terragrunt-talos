variable "libvirt_uri" {
  type = string
}

variable "name" {
  type = string
}

variable "bridge_name" {
  description = "Host bridge device; libvirt generates a name if empty, but a fixed one makes firewall rules predictable."
  type        = string
}

variable "gateway" {
  description = "Address of the host on this network, also the default gateway for the VMs."
  type        = string
}

variable "prefix" {
  type = number
}

variable "domain" {
  type = string
}

variable "dhcp_start" {
  type = string
}

variable "dhcp_end" {
  type = string
}

variable "reservations" {
  description = "Static DHCP leases keyed by node name."
  type = map(object({
    mac = string
    ip  = string
  }))
}
