locals {
  # Cilium refuses to start its Gateway controller unless all of these exist, and CRDs installed afterwards are not
  # picked up without restarting the operator. Installing them first avoids that entirely.
  gateway_api_crds = [
    "gatewayclasses",
    "gateways",
    "httproutes",
    "referencegrants",
    "grpcroutes",
    "backendtlspolicies",
    "tlsroutes",
  ]
}

data "http" "gateway_api_crd" {
  for_each = toset(local.gateway_api_crds)

  url = "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/${var.gateway_api_version}/config/crd/standard/gateway.networking.k8s.io_${each.key}.yaml"

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Could not download the ${each.key} CRD for Gateway API ${var.gateway_api_version}."
    }
  }
}

# Server-side apply because these CRDs exceed the annotation size limit of a client-side apply.
resource "kubectl_manifest" "gateway_api_crd" {
  for_each = data.http.gateway_api_crd

  yaml_body         = each.value.response_body
  server_side_apply = true
}

resource "helm_release" "cilium" {
  name       = "cilium"
  namespace  = "kube-system"
  repository = "https://helm.cilium.io"
  chart      = "cilium"
  version    = var.cilium_version
  timeout    = 600
  wait       = true

  values = [yamlencode({
    # Cilium's own IPAM would fight Kubernetes' per-node pod CIDRs, which Talos already allocates.
    ipam                 = { mode = "kubernetes" }
    kubeProxyReplacement = true

    # KubePrism, Talos' local API server proxy, is reachable on every node and survives control plane restarts. It is
    # also the only address that works before the CNI is up.
    k8sServiceHost = "localhost"
    k8sServicePort = 7445

    # Talos mounts cgroups itself and does not allow the agent to, and it drops capabilities the chart would
    # otherwise grant, so both are spelled out per the Talos Cilium guide.
    cgroup = {
      autoMount = { enabled = false }
      hostRoot  = "/sys/fs/cgroup"
    }
    securityContext = {
      capabilities = {
        ciliumAgent      = ["CHOWN", "KILL", "NET_ADMIN", "NET_RAW", "IPC_LOCK", "SYS_ADMIN", "SYS_RESOURCE", "DAC_OVERRIDE", "FOWNER", "SETGID", "SETUID"]
        cleanCiliumState = ["NET_ADMIN", "SYS_ADMIN", "SYS_RESOURCE"]
      }
    }

    gatewayAPI = {
      enabled           = true
      enableAlpn        = true
      enableAppProtocol = true
    }

    # No cloud load balancer exists here, so Cilium answers ARP for the Gateway's LoadBalancer IP itself. The raised
    # client rate limit is needed because L2 leader election renews leases through the API server.
    l2announcements    = { enabled = true }
    k8sClientRateLimit = { qps = 20, burst = 40 }

    # One operator replica is enough for three nodes and saves memory on the workers.
    operator = { replicas = 1 }

    hubble = {
      enabled = true
      relay   = { enabled = true }
      ui      = { enabled = true }
    }
  })]

  depends_on = [kubectl_manifest.gateway_api_crd]
}

resource "kubectl_manifest" "lb_pool" {
  yaml_body = yamlencode({
    apiVersion = "cilium.io/v2"
    kind       = "CiliumLoadBalancerIPPool"
    metadata   = { name = "lab" }
    spec = {
      blocks = [{
        start = var.lb_pool.start
        stop  = var.lb_pool.stop
      }]
    }
  })

  depends_on = [helm_release.cilium]
}

resource "kubectl_manifest" "l2_policy" {
  yaml_body = yamlencode({
    apiVersion = "cilium.io/v2alpha1"
    kind       = "CiliumL2AnnouncementPolicy"
    metadata   = { name = "lab" }
    spec = {
      loadBalancerIPs = true
    }
  })

  depends_on = [helm_release.cilium]
}
