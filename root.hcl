# State stays local on purpose: this is a single-host lab and a remote backend would only add a chicken-and-egg problem.
# It does hold machine secrets and the kubeconfig, which is why the encryption block below is mandatory.
remote_state {
  backend = "local"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }

  config = {
    path = "${get_parent_terragrunt_dir()}/.state/${path_relative_to_include()}.tfstate"
  }
}

# Generated rather than committed because OpenTofu does not allow variables inside an encryption block. get_env has no
# default so a missing passphrase fails loudly instead of silently producing unencrypted state. The generated file
# lives in .terragrunt-cache, which is gitignored.
generate "encryption" {
  path      = "encryption.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOT
    terraform {
      encryption {
        key_provider "pbkdf2" "lab" {
          passphrase = "${get_env("TOFU_STATE_PASSPHRASE")}"
        }

        method "aes_gcm" "lab" {
          keys = key_provider.pbkdf2.lab
        }

        state {
          method   = method.aes_gcm.lab
          enforced = true
        }

        plan {
          method   = method.aes_gcm.lab
          enforced = true
        }
      }
    }
  EOT
}
