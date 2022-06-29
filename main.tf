provider "google" {
  #  credentials = file("terraform-348105-3a95cf2fec51.json")
  credentials = file("gcertifica-vpn-3d5c17cab3c9.json")
  project     = "gcertifica-vpn"
  region      = "southamerica-east1"
  zone        = "southamerica-east1-a"
}

resource "google_compute_address" "static" {
  name = "ipv4-address"
}

resource "google_compute_instance" "vm_instance" {
  name         = "manserv"
  machine_type = "e2-medium"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network = "projects/gcertifica-vpn/global/networks/gcertifica-vpc"
    subnetwork = "dev"
    access_config {
      nat_ip = google_compute_address.static.address
    }
  }

  metadata = {
    ssh-keys = "gcertifica:${file("gcertificakey.pub")}"
  }

  provisioner "file" {
    source      = "script.sh"
    destination = "/tmp/script.sh"

    connection {
      user        = "gcertifica"
      type        = "ssh"
      host        = self.network_interface[0].access_config[0].nat_ip
      private_key = file("gcertificakey")
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/script.sh",
      "sudo sh /tmp/script.sh",
      "curl -fsSL https://get.docker.com -o /tmp/get-docker.sh",
      "sudo sh /tmp/get-docker.sh"
    ]
    connection {
      user        = "gcertifica"
      type        = "ssh"
      host        = self.network_interface[0].access_config[0].nat_ip
      private_key = file("gcertificakey")
    }
  }
}


