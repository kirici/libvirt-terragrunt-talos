variable "cluster_name" {
  type = string
}

variable "talos_version" {
  type = string
}

variable "kubernetes_version" {
  description = "Empty uses the version shipped with the chosen Talos release."
  type        = string
  default     = ""
}

variable "installer_image" {
  type = string
}

variable "install_disk" {
  type    = string
  default = "/dev/vda"
}

variable "nodes" {
  type = map(object({
    role = string
    ip   = string
  }))

  validation {
    condition     = length([for n in var.nodes : n if n.role == "controlplane"]) == 1
    error_message = "Exactly one controlplane node is supported: the API endpoint is that node's IP. More than one needs a VIP or load balancer in front first."
  }
}
