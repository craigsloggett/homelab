resource "digitalocean_ssh_key" "default" {
  name       = "Default"
  public_key = file(var.ssh_key_path)
}

resource "digitalocean_droplet" "droplet" {
  image     = "debian-11-x64"
  name      = "n1mbu5"
  region    = "tor1"
  size      = "s-1vcpu-1gb"
  user_data = file("cloud-init.yaml")
  ssh_keys  = [digitalocean_ssh_key.default.fingerprint]
}

resource "digitalocean_firewall" "ssh" {
  name        = "SSH"
  droplet_ids = [digitalocean_droplet.droplet.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
}

resource "digitalocean_firewall" "wireguard" {
  name        = "Wireguard"
  droplet_ids = [digitalocean_droplet.droplet.id]

  inbound_rule {
    protocol         = "udp"
    port_range       = "51820"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
}

resource "digitalocean_firewall" "outbound" {
  name        = "Outbound"
  droplet_ids = [digitalocean_droplet.droplet.id]

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}
