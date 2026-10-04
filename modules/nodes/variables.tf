variable "libvirt_uri" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "pool_name" {
  type = string
}

variable "base_volume_path" {
  type = string
}

variable "network_name" {
  type = string
}

variable "lan_bridge" {
  description = "Existing host bridge to attach a second NIC to. Empty means NAT only."
  type        = string
  default     = ""
}

variable "nodes" {
  type = map(object({
    role       = string
    ip         = string
    mac        = string
    vcpu       = number
    memory_mib = number
    disk_gib   = number
  }))
}
