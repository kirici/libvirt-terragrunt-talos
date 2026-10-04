variable "libvirt_uri" {
  type = string
}

variable "talos_version" {
  type = string
}

variable "extensions" {
  description = "Official Image Factory extension names baked into the image, e.g. siderolabs/qemu-guest-agent."
  type        = list(string)
  default     = []
}

variable "pool_name" {
  type = string
}

variable "pool_path" {
  type = string
}

variable "cache_dir" {
  description = "Where the decompressed raw image is kept between applies."
  type        = string
  default     = "~/.cache/talos-lab"
}
