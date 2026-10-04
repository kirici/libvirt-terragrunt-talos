resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode({
    customization = {
      systemExtensions = {
        officialExtensions = var.extensions
      }
    }
  })
}

locals {
  schematic_id = talos_image_factory_schematic.this.id

  # The URL layout is stable and documented, so building it by hand avoids depending on which URL attributes a given
  # provider release happens to expose.
  image_url       = "https://factory.talos.dev/image/${local.schematic_id}/${var.talos_version}/metal-amd64.raw.zst"
  installer_image = "factory.talos.dev/installer/${local.schematic_id}:${var.talos_version}"

  # Version and schematic are part of the file name so bumping either never reuses a stale download.
  image_name = "talos-${var.talos_version}-${substr(local.schematic_id, 0, 12)}.raw"
  image_path = "${pathexpand(var.cache_dir)}/${local.image_name}"
}

# The provider can upload a local file but cannot decompress, and the factory only serves compressed raw images.
resource "terraform_data" "disk_image" {
  triggers_replace = [local.image_path]

  provisioner "local-exec" {
    command = "bash ${path.module}/scripts/fetch-image.sh"

    environment = {
      IMAGE_URL  = local.image_url
      IMAGE_PATH = local.image_path
    }
  }
}

# Dedicated pool because a fresh Fedora install has no "default" pool, and a separate directory keeps this lab's disks
# easy to find and remove.
resource "libvirt_pool" "this" {
  name = var.pool_name
  type = "dir"

  target = {
    path = var.pool_path
  }

  create = {
    build     = true
    start     = true
    autostart = true
  }
}

resource "libvirt_volume" "base" {
  name = local.image_name
  pool = libvirt_pool.this.name

  target = {
    format = {
      type = "raw"
    }
  }

  create = {
    content = {
      url = local.image_path
    }
  }

  depends_on = [terraform_data.disk_image]
}
