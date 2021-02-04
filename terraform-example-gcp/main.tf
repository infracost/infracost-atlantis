provider "google" {
 credentials = "{\"type\":\"service_account\"}"
 region      = "us-central1"
}

resource "google_compute_instance" "instance1" {
 name         = "instance1"
 machine_type = "n1-standard-32" # <<<<< Try changing this to n1-standard-8 to compare the costs
 zone         = "us-central1-a"

 boot_disk {
   initialize_params {
     image = "debian-cloud/debian-9"
   }
 }

 scheduling {
   preemptible = true
 }

  guest_accelerator {
    type = "nvidia-tesla-t4" # <<<<< Try changing this to nvidia-tesla-p4 to compare the costs
    count = 4
  }

  network_interface {
    network = "default"

    access_config {
    }
  }
}

resource "google_dns_record_set" "frontend" {
  name = "frontend.123"
  type = "A"
  ttl  = 300
  rrdatas = ["123.123.123.123]"]
  managed_zone = "zone"
}
