# talos-lab

One control plane and two workers running Talos on libvirt, with Cilium (kube-proxy replacement, Gateway API, L2
announced LoadBalancer IPs). OpenTofu modules, driven by Terragrunt.

## Prerequisites for the host

Tested on Fedora 44

```bash
# Packages should be all installed already except for virt-install
sudo dnf install -y \
    qemu-kvm \
    libvirt-daemon-driver-qemu \
    libvirt-daemon-driver-network \
    libvirt-daemon-driver-storage-core \
    libvirt-daemon-config-network \
    libvirt-client \
    edk2-ovmf \
    zstd \
    xz \
    curl \
    virt-install
sudo systemctl enable --now virtqemud.socket virtnetworkd.socket virtstoraged.socket
sudo usermod -aG libvirt $USER
```


## Layout

    root.hcl          local state, with OpenTofu state encryption generated per unit
    live/lab.hcl      the one place to change versions, sizes, IPs and the pool/network names
    live/image        Image Factory schematic, raw image download, storage pool, base volume
    live/network      NAT network with DHCP reservations keyed on node MACs
    live/nodes        qcow2 overlays and domains
    live/cluster      Talos secrets, machine configs, apply, bootstrap, kubeconfig
    live/cni          Gateway API CRDs, Cilium, LB IP pool and L2 announcement policy
    modules/*         the OpenTofu code behind each unit

Dependency order is image and network, then nodes, then cluster, then cni.

## First run

    mise trust && mise install
    mise run secrets      # creates .env.local with the state passphrase, once
    mise run doctor       # libvirt reachable, /dev/kvm readable, user in the libvirt group
    mise run up           # terragrunt run --all apply, then writes out/kubeconfig and out/talosconfig

`terragrunt run --all apply` approves automatically, so read a plan first if that matters:
`cd live/image && terragrunt plan`. Keep `.env.local` safe: losing the passphrase makes the state unreadable.

After `up`, in a shell inside this directory (mise sets KUBECONFIG and TALOSCONFIG):

    kubectl get nodes
    cilium status

The nodes sit NotReady between the cluster and cni units. That is expected, there is no CNI yet.

## Using the Gateway API

Gateways of class `cilium` get a LoadBalancer IP from `lb_pool` (10.5.0.200 to 10.5.0.250 by default), answered over ARP
by one of the nodes. The host reaches those IPs directly through the libvirt bridge.

## Known limits

- `terragrunt run --all plan` fails on the cni unit until the cluster exists, because the helm and kubectl providers
  need a live API server. Plan it after the first apply.
- Exactly one control plane. More needs a VIP or load balancer in front of the API, and a changed endpoint.
- Changing the network unit recreates the libvirt network (the provider forces replacement), which interrupts the VMs.
- The state passphrase is written into the generated `encryption.tf` inside `.terragrunt-cache`. It is gitignored, but
  it is on disk next to the state.

## Open topics

- Tailscale or Headscale on the host as bastion, subnet router for 10.5.0.0/24 and possibly the Gateway entrypoint.
- Optional LAN bridge: set `lan_bridge` in `lab.hcl` to the name of an existing host bridge. It adds a second NIC to
  every node. The host bridge itself is not managed here.
