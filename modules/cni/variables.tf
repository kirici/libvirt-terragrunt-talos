variable "kubernetes" {
  type = object({
    host               = string
    ca_certificate     = string
    client_certificate = string
    client_key         = string
  })
  sensitive = true
}

variable "cilium_version" {
  type = string
}

variable "gateway_api_version" {
  description = "Must match what the chosen Cilium release supports; the Cilium Gateway API docs state the version."
  type        = string
}

variable "lb_pool" {
  description = "Address range Cilium hands out to LoadBalancer services, including Gateways."
  type = object({
    start = string
    stop  = string
  })
}
