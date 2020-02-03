terraform {
  required_version = "~> 0.12.8"
  required_providers {
    openstack = "~> 1.24"
    tls       = "~> 2.1"
  }
}

variable nb {
  description = "Number of instances to deploy"
  default     = 3
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "openstack_compute_keypair_v2" "keypair" {
  name       = "tf-keypair"
  public_key = tls_private_key.private_key.public_key_openssh
}

data "openstack_networking_network_v2" "ext_net" {
  name      = "Ext-Net"
  tenant_id = ""
}

resource "openstack_networking_port_v2" "public_port" {
  count          = var.nb
  name           = "tf-publicport-${format("%03d", count.index)}"
  network_id     = data.openstack_networking_network_v2.ext_net.id
  admin_state_up = "true"
}

resource "openstack_compute_instance_v2" "node" {
  count       = var.nb
  name        = "tf-instance-${format("%03d", count.index)}"
  image_name  = "Ubuntu 18.04"
  flavor_name = "s1-4"
  key_pair    = openstack_compute_keypair_v2.keypair.name
  network {
    port = openstack_networking_port_v2.public_port[count.index].id
  }

  lifecycle {
    ignore_changes = [user_data, image_id, key_pair]
  }
}

output keypair_priv {
  description = "SSH private key"
  sensitive   = true
  value       = tls_private_key.private_key.private_key_pem
}
