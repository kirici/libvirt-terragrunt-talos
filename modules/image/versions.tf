terraform {
  required_version = ">= 1.10"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.9.9"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.12"
    }
  }
}

provider "libvirt" {
  uri = var.libvirt_uri
}
