terraform {
  required_version = ">= 1.10"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4"
    }
  }
}

# This unit exists separately from cluster because these providers need a reachable API server at plan time, which a
# single-unit design cannot offer on the first apply.
provider "helm" {
  kubernetes = {
    host                   = var.kubernetes.host
    cluster_ca_certificate = base64decode(var.kubernetes.ca_certificate)
    client_certificate     = base64decode(var.kubernetes.client_certificate)
    client_key             = base64decode(var.kubernetes.client_key)
  }
}

provider "kubectl" {
  host                   = var.kubernetes.host
  cluster_ca_certificate = base64decode(var.kubernetes.ca_certificate)
  client_certificate     = base64decode(var.kubernetes.client_certificate)
  client_key             = base64decode(var.kubernetes.client_key)
  load_config_file       = false
}
