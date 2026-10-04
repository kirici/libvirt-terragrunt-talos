output "pool_name" {
  value = libvirt_pool.this.name
}

output "base_volume_path" {
  value = libvirt_volume.base.path
}

output "schematic_id" {
  value = local.schematic_id
}

output "installer_image" {
  description = "Goes into machine.install.image so later Talos upgrades keep the same extensions."
  value       = local.installer_image
}
