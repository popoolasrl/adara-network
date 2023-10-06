provider "google" {
  credentials = file("C:/application_default_credentials.json")
  project     = "my-project-81925-popoola"
  region      = "us-west2"
}

resource "google_compute_network" "adara-net" {
  name = "adara-net"
}

resource "google_compute_subnetwork" "adara-pubsubnet" {
  name          = "adara-pubsubnet"
  network = google_compute_network.adara-net.id
  ip_cidr_range = "10.122.2.0/24"
  region        = "us-west2"
}

resource "google_compute_subnetwork" "adara-privsubnet-1" {
  name = "adara-privsubnet-1"
  network = google_compute_network.adara-net.id
  ip_cidr_range = "10.122.6.0/24"
  region = "us-west2"
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "adara-privsubnet-2" {
  name = "adara-privsubnet-2"
  network = google_compute_network.adara-net.id
  ip_cidr_range = "10.122.7.0/24"
  region = "us-west2"
  private_ip_google_access = true
}

resource "google_compute_router" "adara-router" {
  name    = "adara-router"
  region  = google_compute_subnetwork.adara-privsubnet-1.region
  network = google_compute_network.adara-net.id
}

resource "google_compute_router_nat" "adara-nat" {
  name                               = "adara-nat"
  router                             = google_compute_router.adara-router.id
  region                             = google_compute_router.adara-router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_instance" "Adara-vm-priv" {
  name = "Adara-vm-priv"
  machine_type = "n2-standard-2"
  zone = "us-west2"

boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network = google_compute_network.adara-net.id
    subnetwork = google_compute_subnetwork.adara-privsubnet-1.id
    access_config {
      // Ephemeral IP
    }
  }
}

resource "google_compute_instance_group" "webservers" {
  name        = "terraform-webservers"
  description = "Terraform test instance group"
  zone = "us-west2"

  instances = [
    google_compute_instance.Adara-vm-priv.id    
  ]

  named_port {
    name = "http"
    port = "80"
  }

  named_port {
    name = "https"
    port = "443"
  }
}



# # Declare the google_compute_disk resource
# resource "google_compute_disk" "existing_vm_disk" {
#   name = "example-disk"
#   # Configuration for the existing_vm_disk resource
# }

# # Declare the google_compute_image resource
# resource "google_compute_image" "custom_image" {
#   name = "custom-image"
#   source_disk = google_compute_disk.existing_vm_disk.self_link
#   # Configuration for the custom_image resource
# }

# # Create an instance template based on the custom image
# resource "google_compute_instance_template" "instance_template" {
#   name        = "instance-template"
#   description = "Instance template based on custom image"
#   machine_type = "n2-standard-2"

#   disk {
#     source_image = google_compute_image.custom_image.self_link
#   }

#   network_interface {
#     network = "default"
#   }
# }

# # Output the instance template self link
# output "instance_template_self_link" {
#     value = google_compute_instance_template.instance_template.self_link
# }

# # Output the custom image self link
# output "custom_image_self_link" {
#   value = google_compute_image.custom_image.self_link
# }

# resource "google_compute_autoscaling_policy" "adara_vm_priv" {
#   name = "adara_vm_priv"
#   zone = "us-west2"
#   target = google_compute_instance_group.adara_vm_priv_asg.id
#   min_instances = 1
#   max_instances = 10
#   cpu_utilization {
#     target = 0.5
#   }
# }